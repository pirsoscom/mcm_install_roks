#!/bin/bash

# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Functions for install scripts
#
# V1.0 
#
# ©2020 nikh@ch.ibm.com
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"




# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Init Code
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # fix sed issue on mac
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        SED="sed"
        if [ "${OS}" == "darwin" ]; then
            SED="gsed"
            if [ ! -x "$(command -v ${SED})"  ]; then
            echo "This script requires $SED, but it was not found.  Perform \"brew install gnu-sed\" and try again."
            exit
            fi
        fi




# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Functions
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"


    # ---------------------------------------------------------------------------------------------------------------------------------------------------"
    # Helpers
    # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        function getClusterFQN() {
        echo "  "
        echo " ${PURPLE}Determining Cluster FQN${NC}"
            CLUSTER_ROUTE=$(kubectl get routes console -n openshift-console | tail -n 1 2>&1 ) 
            if [[ $CLUSTER_ROUTE =~ "reencrypt" ]];
            then
            CLUSTER_FQDN=$( echo $CLUSTER_ROUTE | awk '{print $2}')
           
            CLUSTER_NAME=$(echo $CLUSTER_FQDN | ${SED} "s/$OCP_CONSOLE_PREFIX.//")
            

            export CONSOLE_URL=$OCP_CONSOLE_PREFIX.$CLUSTER_NAME
            export MCM_SERVER=https://icp-console.$CLUSTER_NAME

            echo "    ${GREEN}Cluster FQDN:${NC}                        '$CLUSTER_NAME'"
            #return $CLUSTER_NAME
            else
            echo "    ${RED}Cannot determine Route${NC}"
            echo "    ${ORANGE}Check your Kubernetes Configuration${NC}"
            echo "    ${RED}Aborting${NC}"
            exit 1
            fi
        }



        function getHosts() {
        echo "  "
        echo " ${ORANGE}Installation Nodes not set${NC}"
        echo " ${PURPLE}  Determining Cluster Node IPs${NC}"
            CLUSTERS=$(kubectl get nodes 2>&1 ) 

            if [[ $CLUSTERS =~ "NAME" ]];
            then
            CLUSTER_W1=$( kubectl get nodes | sed -n 2p | awk '{print $1}' 2>&1 ) 
            CLUSTER_W2=$( kubectl get nodes | sed -n 3p | awk '{print $1}' 2>&1 ) 

            export MASTER_HOST=$CLUSTER_W1
            export PROXY_HOST=$CLUSTER_W1
            export MANAGEMENT_HOST=$CLUSTER_W2

            echo "    ${GREEN}Setting Master to: ${NC}                 '$MASTER_HOST'"
            echo "    ${GREEN}Setting Proxy to: ${NC}                  '$PROXY_HOST'"
            echo "    ${GREEN}Setting Management to: ${NC}             '$MANAGEMENT_HOST'"
            else
            echo "    ${RED}Cannot determine Cluster Nodes${NC}"
            echo "    ${ORANGE}Check your Kubernetes Configuration${NC}"
            echo "    ${RED}Aborting${NC}"
            exit 1
            fi
        }




        function assignHosts() {
            echo "     ${CYAN}Assign Hosts${NC}"
            export MASTER_COMPONENTS=$MASTER_HOST  #.$CLUSTER_NAME
            export PROXY_COMPONENTS=$PROXY_HOST  #.$CLUSTER_NAME
            export MANAGEMENT_COMPONENTS=$MANAGEMENT_HOST  #.$CLUSTER_NAME
        }




        function getInstallPath() {
            echo "    Get ${CYAN}Temp Directory${NC} Path"
            export INSTALL_PATH=$TEMP_PATH/$0/$CLUSTER_NAME
        }



      function createToken
        {
            echo "     ${CYAN}Create Token${NC}"
            export serviceIDName='service-deploy'
            export serviceApiKeyName='service-deploy-api-key'
            
            LOGIN_OK=$(cloudctl login -a ${MCM_SERVER} --skip-ssl-validation -u ${MCM_USER} -p ${MCM_PWD} -n kservices)
            if [[ $LOGIN_OK =~ "Error response from server" ]];
            then
                echo "    ${RED}ERROR${NC}: Could not login to MCM Hub on Cluster '$CLUSTER_NAME'. Aborting."
                exit 2
            fi

            cloudctl iam service-id-delete ${serviceIDName} -f
            #cloudctl iam service-api-key-delete ${serviceApiKeyName} ${serviceIDName} -f

            cloudctl iam service-id-create ${serviceIDName} -d 'Service ID for service-deploy'
            cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'idmgmt'
            cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'identity'
            cloudctl iam service-api-key-create ${serviceApiKeyName} ${serviceIDName} -d 'Api key for service-deploy' > token.txt
        }





    # ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    # PRE-INSTALL CHECKS
    # ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
         function dockerRunning() {
            echo "    Check if ${CYAN}Docker${NC} is running"
            DOCKER_RESOLVE=$(docker ps 2>&1)
            if [[ $DOCKER_RESOLVE =~ "CONTAINER ID" ]];
            then
                echo "    ${GREEN}  OK${NC}"
            else 
                echo "    ${RED}  ERROR${NC}: Docker '$CLUSTER_NAME' is not running"
                echo "           ${RED}Aborting.${NC}"
                exit 1
            fi
            echo ""
        }
 
 
 
        function checkOpenshiftReachable() {
            echo "    Check if ${CYAN}OpenShift${NC} is reachable at               $CONSOLE_URL"
            PING_RESOLVE=$(ping -c 1 $CONSOLE_URL 2>&1)
            if [[ $PING_RESOLVE =~ "cannot resolve" ]];
            then
                echo "    ${RED}  ERROR${NC}: Cluster '$CLUSTER_NAME' is not reachable"
                echo "           ${RED}Aborting.${NC}"
                exit 1
            else 
                echo "    ${GREEN}  OK${NC}"
            fi
            echo ""
        }


        function checkKubeconfigIsSet() {
            echo "    Check if OpenShift ${CYAN}KUBECONTEXT${NC} is set for        $CLUSTER_NAME"
            KUBECTX_RESOLVE=$(kubectl get routes --all-namespaces 2>&1)


            if [[ $KUBECTX_RESOLVE =~ $CLUSTER_NAME ]];
            then
                echo "    ${GREEN}  OK${NC}"
            else 
                echo "    ${RED}  ERROR${NC}: Please log into  '$CLUSTER_NAME' via the OpenShift web console"
                echo "           ${RED}Aborting.${NC}"
                exit 1
            fi
            echo ""

        }


        function checkStorageClassExists() {
            echo "    Check if ${CYAN}Storage Class${NC} $STORAGE_CLASS_BLOCK exists on                 $CLUSTER_NAME"
            SC_RESOLVE=$(oc get sc 2>&1)

            if [[ $SC_RESOLVE =~ $STORAGE_CLASS_BLOCK ]];
            then
                echo "    ${GREEN}  OK: Storage Class exists${NC}"
            else 
                echo "    ${RED}  ERROR${NC}: Storage Class does not exist."
                echo "           ${RED}Aborting.${NC}"
                exit 1
            fi
            echo ""
        }


        function checkDefaultStorageDefined() {
            echo "    Check if ${CYAN}Default Storage Class${NC} is defined on                 $CLUSTER_NAME"
            SC_RESOLVE=$(oc get sc 2>&1)

            if [[ $SC_RESOLVE =~ (default) ]];
            then
                echo "    ${GREEN}  OK: Default Storage Class defined${NC}"
            else 
                echo "    ${RED}  ERROR${NC}: No default Storage Class defined."
                echo "           Define Annotation: storageclass.kubernetes.io/is-default-class=true"
                echo "           ${RED}Aborting.${NC}"
                exit 1
            fi
            echo ""
        }


        function checkRegistryCredentials() {
            echo "    Check if ${CYAN}Docker Registry Credentials${NC} work ($ENTITLED_REGISTRY_KEY)"
            echo "    This might take some time"

            #docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY"

            DOCKER_LOGIN=$(docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY" 2>&1)
            echo $DOCKER_LOGIN

            docker pull $ENTITLED_REGISTRY/cp/icp-foundation/mcm-inception:$MCM_VERSION

            DOCKER_PULL=$(docker pull $ENTITLED_REGISTRY/cp/icp-foundation/mcm-inception:$MCM_VERSION 2>&1)

            if [[ $DOCKER_PULL =~ "pull access denied" ]];
            then
                echo "${RED}  ERROR${NC}: Not entitled for Registry or not reachable"
                echo "           ${RED}Aborting.${NC}"
                exit 1
            else
                echo "    ${GREEN}  OK${NC}"
            fi
            echo ""
        }

        function checkClusterServiceBroker() {
            echo "    Check if ${CYAN}ClusterServiceBroker${NC} exists on          $CLUSTER_NAME"
            CSB_RESOLVE=$(kubectl api-resources 2>&1)

            if [[ $CSB_RESOLVE =~ "servicecatalog.k8s.io" ]];
            then
                echo "    ${GREEN}  OK${NC}"
            else 
                echo "    ${RED}  ERROR${NC}: ClusterServiceBroker does not exist on Cluster '$CLUSTER_NAME'. Aborting."
                echo "      Install ClusterServiceBroker on OpenShift 4.2"
                echo "      https://docs.openshift.com/container-platform/4.2/applications/service_brokers/installing-service-catalog.html"
                echo "     "
                #kubectl get servicecatalogapiservers cluster -oyaml --export | sed -e '/status:/d' -e '/creationTimestamp:/d' -e '/selfLink: [a-z0-9A-Z/]\+/d' -e '/resourceVersion: "[0-9]\+"/d' -e '/phase:/d' -e '/uid: [a-z0-9-]\+/d'
                #kubectl get servicecatalogcontrollermanagers cluster -oyaml --export | sed -e '/status:/d' -e '/creationTimestamp:/d' -e '/selfLink: [a-z0-9A-Z/]\+/d' -e '/resourceVersion: "[0-9]\+"/d' -e '/phase:/d' -e '/uid: [a-z0-9-]\+/d'

                kubectl apply -f ./tools/ServiceCatalogAPIServer.yaml
                kubectl apply -f ./tools/ServiceCatalogControllerManager.yaml

                waitForPod apiserver openshift-service-catalog-apiserver
                waitForPod controller-manager openshift-service-catalog-controller-manager

                #echo "   Update 'Removed' to 'Managed'  "
                #echo "    KUBE_EDITOR="nano" oc edit servicecatalogapiservers" 
                #echo "    KUBE_EDITOR="nano" oc edit servicecatalogcontrollermanagers"
                #exit 1
            fi
            echo ""
        }

        function checkHelmExecutable() {
            echo "    Check ${CYAN}HELM${NC} Version (must be 2.x)"
            HELM_RESOLVE=$($HELM_BIN version 2>&1)

            if [[ $HELM_RESOLVE =~ "v2." ]];
            then
                echo "    ${GREEN}  OK${NC}"
            else 
                echo "    ${RED}  ERROR${NC}: Wrong Helm Version ($HELM_RESOLVE)"
                echo "    ${ORANGE}   Trying 'helm2'"

                export HELM_BIN=helm2
                HELM_RESOLVE=$($HELM_BIN version 2>&1)

                if [[ $HELM_RESOLVE =~ "v2." ]];
                then
                    echo "    ${GREEN}  OK${NC}"
                else 
                    echo "    ${RED}  ERROR${NC}: Helm Version 2 does not exist in your Path"
                    echo "      Please install from https://icp-console.$CLUSTER_NAME/common-nav/cli?useNav=multicluster-hub-nav-nav"
                    echo "       or run"
                    echo "     curl -sL https://ibm.biz/idt-installer | bash"
                    echo "           ${RED}Aborting.${NC}"
                    exit 1
                fi
            fi
            echo ""
        }


        function checkCloudctlExecutable() {
            echo "    Check if ${CYAN}cloudctl${NC} Command Line Tool is available"
            CLOUDCTL_RESOLVE=$(cloudctl 2>&1)

            if [[ $CLOUDCTL_RESOLVE =~ "USAGE" ]];
            then
                echo "    ${GREEN}  OK${NC}"
            else 
                echo "    ${RED}  ERROR${NC}: cloudctl Command Line Tool does not exist in your Path"
                echo "      Please install from https://icp-console.$CLUSTER_NAME/common-nav/cli?useNav=multicluster-hub-nav-nav"
                echo "       or run"
                echo "      curl -sL https://ibm.biz/idt-installer | bash"
                echo "           ${RED}Aborting.${NC}"
                exit 1
            fi
            echo ""
        }

  






    # ---------------------------------------------------------------------------------------------------------------------------------------------------"
    # Unused
    # ----^-----------------------------------------------------------------------------------------------------------------------------------------------"
        function waitForPod() {
            FOUND=1
            MINUTE=0
            podName=$1
            namespace=$2
            runnings="$3"
            echo "Wait for ${podName} to reach running state (4min)."
            while [ ${FOUND} -eq 1 ]; do
                # Wait up to 4min, should only take about 20-30s
                if [ $MINUTE -gt 240 ]; then
                    echo "Timeout waiting for the ${podName}. Try cleaning up using the uninstall scripts before running again."
                    echo "List of current pods:"
                    oc -n ${namespace} get pods
                    echo
                    echo "You should see ${podName}, multiclusterhub-repo, and multicloud-operators-subscription pods"
                    exit 1
                fi

                operatorPod=`oc -n ${namespace} get pods | grep ${podName}`
              
                if [[ "$operatorPod" =~ "${running}     Running" ]]; then
                    echo "* ${podName} is running"
                    break
                elif [ "$operatorPod" == "" ]; then
                    operatorPod="Waiting"
                fi
                echo "* STATUS: $operatorPod"
                sleep 3
                (( MINUTE = MINUTE + 3 ))
            done
            printf "#####\n\n"
        }

