# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Install Kubernetes Monitoring
#
# V1.0 
#
# ©2020 nikh@ch.ibm.com
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"

source ./0_variables.sh


# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Do Not Edit Below
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo " ${CYAN}  Register Kubernetes Monitoring for OpenShift 4.3${NC}"
echo "  "
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "



# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# GET PARAMETERS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Input Parameters${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"



        while getopts "d:n:f:i:" opt
        do
          case "$opt" in
              f ) INPUT_CONFIG="$OPTARG" ;;
              i ) INPUT_PPA="$OPTARG" ;;
              d ) INPUT_PATH="$OPTARG" ;;
          esac
        done


        if [[ $INPUT_CONFIG == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the ibm-cloud-apm-dc-configpack.tar file"
            echo "    USAGE: $0 -d <DOCKER_DOMAIN> -f <CONFIGURATION_FILE> -i <PPA_FILE>  "
            exit 1
        else
          echo "    ${GREEN}Config File OK:${NC}                      $INPUT_CONFIG"
          K8M_CONFIG=$INPUT_CONFIG
        fi


        if [[ $INPUT_PPA == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the PPA install file (like agent_ppa_2020.1.0_prod_amd64.tar.gz)"
            echo "    USAGE: $0 -d <DOCKER_DOMAIN> -f <CONFIGURATION_FILE> -i <PPA_FILE>   "
            exit 1
        else
          echo "    ${GREEN}PPA File OK:${NC}                         $INPUT_PPA"
          PPA_CONFIG=$INPUT_PPA
        fi


        if [[ $INPUT_PATH == "" ]];
        then
          echo "    ${ORANGE}No Path provided, using${NC}             '$TEMP_PATH'"
        else
          echo "    ${GREEN}Path OK:${NC}                             '$INPUT_PATH'"
          TEMP_PATH=$INPUT_PATH
        fi


echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PRE-INSTALL CHECKS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Pre-Install Checks${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"

        checkOpenshiftReachable

        #checkHelmChartInstalled "icam-kubernetes-resources"

        echo "    Check if ${CYAN}$K8M_CONFIG${NC} exists"
        if test -f "$K8M_CONFIG"; then
            echo "    ${GREEN}  OK${NC}"
        else 
            echo "    ${RED}  ERROR${NC}: ${ORANGE}ibm-cloud-apm-dc-configpack.tar${NC} does not exist in your Path"
            echo "           ${RED}Aborting.${NC}"
            exit 1
        fi


        echo "    Check if ${CYAN}$PPA_CONFIG${NC} exists"
        if test -f "$PPA_CONFIG"; then
            echo "    ${GREEN}  OK${NC}"
        else 
            echo "    ${RED}  ERROR${NC}: ${ORANGE}ibm-cloud-apm-dc-configpack.tar${NC} does not exist in your Path"
            echo "           ${RED}Aborting.${NC}"
            exit 1
        fi


echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "



# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Define some Stuff
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Define some Stuff${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"

        getClusterFQDN

        getInstallPath

        export my_registry_name="image-registry-openshift-image-registry."$CLUSTER_NAME

echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CONFIG SUMMARY
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}  Cluster ${ORANGE}'$CLUSTER_NAME'${NC} will be registered with the Monitoring Module (APM)"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " ${BLUE}Your configuration${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CLUSTER TO BE REGISTERED :${NC}   $CLUSTER_NAME"
echo "    ------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}Docker Domain for images:${NC}    $my_registry_name"
echo "    ------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}Configuration file:${NC}          $K8M_CONFIG"
echo "    ${GREEN}PPA File:${NC}                    $PPA_CONFIG"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "


echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${RED}Continue Installation with these Parameters? [y,N]${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
        read -p "[y,N]" DO_COMM
        if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
          echo "${GREEN}Continue...${NC}"
        else
          echo "${RED}Installation Aborted${NC}"
          exit 2
        fi
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PREREQUISITES
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${CYAN}Running Prerequisites${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"

        export SCRIPT_PATH=$(pwd)

        echo " ${wrench} Create Config Directory"
          rm -r $INSTALL_PATH/* 
          mkdir -p $INSTALL_PATH 
        echo "    ${GREEN}  OK${NC}"
        echo "  "


        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Copying ${CYAN}Files${NC}"
        cp $PPA_CONFIG $INSTALL_PATH/agent_ppa_2020.1.0_prod_amd64.tar.gz
        cp $K8M_CONFIG $INSTALL_PATH/ibm-cloud-apm-dc-configpack.tar
        mkdir -p $INSTALL_PATH/deploy
        cp -r ./tools/apm/deploy/* $INSTALL_PATH/deploy
        cd $INSTALL_PATH


        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Loading ${CYAN}Images${NC} to Openshift Registry "

        echo " ${wrench} Unpacking ${CYAN}Images${NC} "
        tar xvf agent_ppa_2020.1.0_prod_amd64.tar.gz images/

        echo " ${wrench} Adapt ${CYAN}Registry Route${NC} "
        export local_registry=$(oc registry info)
        oc create route reencrypt --service=image-registry
        oc get route image-registry


        echo " ${wrench} Docker ${CYAN}Login${NC} "
        docker login -u $(oc whoami) -p $(oc whoami -t) "$my_registry_name"

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Loading ${CYAN}Agentoperator Image${NC}"
        docker load -i images/agentoperator_APM_202003100816.tar.gz
        docker tag agentoperator:APM_202003100816 $my_registry_name/multicluster-endpoint/agentoperator:APM_202003100816  
        docker push $my_registry_name/multicluster-endpoint/agentoperator:APM_202003100816

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Loading ${CYAN}K9sMonitor Image${NC}"
        docker load -i images/k8-monitor_APM_202003092352.tar.gz
        docker tag k8-monitor:APM_202003092352 $my_registry_name/multicluster-endpoint/k8-monitor:APM_202003092352  
        docker push $my_registry_name/multicluster-endpoint/k8-monitor:APM_202003092352
       
        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Loading ${CYAN}k8sdc-Operator Image${NC}"
        docker load -i images/k8sdc-operator_APM_202003092352.tar.gz
        docker tag k8sdc-operator:APM_202003092352 $my_registry_name/multicluster-endpoint/k8sdc-operator:APM_202003092352  
        docker push $my_registry_name/multicluster-endpoint/k8sdc-operator:APM_202003092352
       
        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Loading ${CYAN}Reloader Image${NC}"
        docker load -i images/reloader_202002170811-multi-arch.tar.gz
        docker tag reloader:202002170811-multi-arch $my_registry_name/multicluster-endpoint/reloader:202002170811-multi-arch  
        docker push $my_registry_name/multicluster-endpoint/reloader:202002170811-multi-arch


        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Unpack ${CYAN}Configpack${NC}"
        cp $K8M_CONFIG .
        tar -xvf ./ibm-cloud-apm-dc-configpack.tar

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Cluster Roles${NC}"
        oc create clusterrolebinding icamklust-binding --clusterrole=cluster-admin \
        --serviceaccount=multicluster-endpoint:icamklust -n multicluster-endpoint

        oc create clusterrolebinding icamklust-binding_default --clusterrole=cluster-admin \
          --serviceaccount=multicluster-endpoint:default -n multicluster-endpoint

        oc adm policy add-cluster-role-to-user cluster-admin IAM#nikh@ch.ibm.com --as=system:admin

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Secrets${NC}"
        kubectl -n multicluster-endpoint create -f ./ibm-cloud-apm-dc-configpack/dc-secret.yaml

        kubectl -n multicluster-endpoint create secret generic ibm-agent-https-secret --from-file=./ibm-cloud-apm-dc-configpack/keyfiles/cert.pem --from-file=./ibm-cloud-apm-dc-configpack/keyfiles/ca.pem --from-file=./ibm-cloud-apm-dc-configpack/keyfiles/key.pem


        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Adapting ${CYAN}YAML Files${NC}"

        ${SED} -i "s/MY_REGISTRY/$local_registry/" deploy/agentoperator.yaml
        ${SED} -i "s/MY_REGISTRY/$local_registry/" deploy/icam-reloader.yaml
        ${SED} -i "s/MY_REGISTRY/$local_registry/" deploy/operator.yaml





echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INSTALL
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${ORANGE}Installing....${NC}"
echo ""
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"


        kubectl apply -n multicluster-endpoint -f ./deploy/crds/k8sdc_crd.yaml
        kubectl apply -n multicluster-endpoint -f ./deploy/agentoperator.yaml
        kubectl apply -n multicluster-endpoint -f ./deploy/icam-reloader.yaml
        kubectl apply -n multicluster-endpoint -f ./deploy/operator.yaml
        kubectl apply -n multicluster-endpoint -f ./deploy/role.yaml
        kubectl apply -n multicluster-endpoint -f ./deploy/role_binding.yaml
        kubectl apply -n multicluster-endpoint -f ./deploy/service_account.yaml

        waitForPodsReady "multicluster-endpoint"


echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN} Cluster ${ORANGE}'$CLUSTER_NAME'${NC} registered with the Monitoring Module.... DONE${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}To remove release: "
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"


exit 1

# PUSH IMAGES (RUN ONCE)
docker login -u niklaushirt -p xxxx
ansible-playbook helm-main.yaml --extra-vars="cluster_name=mcm-hub release_name=icam-kubernetes-resources namespace=k8-monitor docker_group=niklaushirt tls_enabled=true docker_registry=docker.io" 
docker tag icam-k8-monitor:APM_202003092352 docker.io/niklaushirt/k8-monitor:APM_202003092352
docker push docker.io/niklaushirt/k8-monitor:APM_202003092352




oc create clusterrolebinding icamklust-binding --clusterrole=cluster-admin \
 --serviceaccount=multicluster-endpoint:icamklust -n multicluster-endpoint

 oc create clusterrolebinding icamklust-binding_default --clusterrole=cluster-admin \
   --serviceaccount=multicluster-endpoint:default -n multicluster-endpoint
oc adm policy add-cluster-role-to-user cluster-admin IAM#nikh@ch.ibm.com --as=system:admin


oc create clusterrolebinding svcreg-binding --clusterrole=cluster-admin \
 --serviceaccount=multicluster-endpoint:endpoint-svcreg -n multicluster-endpoint

oc create clusterrolebinding test-binding --clusterrole=cluster-admin \
 --serviceaccount=hcm:clusters:mcm-hub:mcm-hub -n multicluster-endpoint


oc adm policy add-cluster-role-to-user cluster-admin hcm:clusters:mcm-hub:mcm-hub --as=system:admin




endpoint-svcreg


kubectl -n multicluster-endpoint create -f /Users/nhirt/ibm-cloud-apm-dc-configpack/dc-secret.yaml

kubectl -n multicluster-endpoint create secret generic ibm-agent-https-secret --from-file=/Users/nhirt/ibm-cloud-apm-dc-configpack/keyfiles/cert.pem --from-file=/Users/nhirt/ibm-cloud-apm-dc-configpack/keyfiles/ca.pem --from-file=/Users/nhirt/ibm-cloud-apm-dc-configpack/keyfiles/key.pem

kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/crds/k8sdc_crd.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/agentoperator.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/icam-reloader.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/operator.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/role.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/role_binding.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/service_account.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/crds/k8sdc_cr.yaml

kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/crds/k8sdc_cr.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/agentoperator.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/icam-reloader.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/operator.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/role.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/role_binding.yaml
kubectl delete -f ./tools/apm/deploy/service_account.yaml
kubectl delete -f ./tools/apm/deploy/crds/k8sdc_crd.yaml

oc delete secret dc-secret -n multicluster-endpoint
oc delete secret ibm-agent-https-secret -n multicluster-endpoint

oc delete clusterrolebinding icamklust-binding -n multicluster-endpoint
oc delete clusterrolebinding icamklust-binding_default -n multicluster-endpoint


oc adm policy add-cluster-role-to-user cluster-admin root --as=system:admin
