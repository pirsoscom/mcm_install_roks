# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Install Script for ICAM on IBM ROKS Cloud
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
echo " ${CYAN} Install Ansible Tower for OpenShift 4.3${NC}"
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

        while getopts "d:h:p:x:" opt
        do
          case "$opt" in
              x ) INPUT_CONSOLE_PREFIX="$OPTARG";;
              d ) INPUT_PATH="$OPTARG" ;;
              h ) INPUT_CLUSTER_NAME="$OPTARG" ;;
              p ) INPUT_PWD="$OPTARG" ;;
          esac
        done


        if [[ $INPUT_CONSOLE_PREFIX == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the OCP console prefix (for example console"
          echo "    USAGE: $0 -x <OCP_CONSOLE_PREFIX> [-h <CLUSTER_NAME>] [-p <ANSIBLE_PASSWORD>] [-d <TEMP_DIRECTORY>] "
            exit 1
        else
          echo "    ${GREEN}Console Prefix OK:${NC}                  '$INPUT_CONSOLE_PREFIX'"
          OCP_CONSOLE_PREFIX=$INPUT_CONSOLE_PREFIX
        fi



        if [[ $INPUT_PWD == "" ]];          
        then
          echo "    ${ORANGE}No Password provided, using${NC}         '$MCM_PASSWORD'"
        else
          echo "    ${GREEN}Password OK:${NC}                        '********'"
          MCM_PASSWORD=$INPUT_PWD
        fi



        if [[ $INPUT_PATH == "" ]];
        then
          echo "    ${ORANGE}No Path provided, using${NC}             '$TEMP_PATH'"
        else
          echo "    ${GREEN}Path OK:${NC}                            '$INPUT_PATH'"
          TEMP_PATH=$INPUT_PATH
        fi


        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          getClusterFQN
        fi


        if [[ ($MASTER_HOST == "0.0.0.0") ]];
        then
        getHosts
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

        checkKubeconfigIsSet

        #checkClusterServiceBroker

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

        getInstallPath

        assignHosts

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
echo " ${GREEN} Ansible Tower will be installed in Cluster ${ORANGE}'$CLUSTER_NAME'${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Your configuration${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CLUSTER :${NC}             $CLUSTER_NAME"
echo "    ------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}MCM Server:${NC}           $MCM_SERVER"
echo "    ${GREEN}MCM User Name:${NC}        $MCM_USER"
echo "    ${GREEN}MCM User Password:${NC}    ************"
echo "    ---------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}ANSIBLE COMPONENTS:${NC}   $MASTER_COMPONENTS"
echo "    ------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}INSTALL PATH:${NC}         $INSTALL_PATH"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
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

        echo "---------------------------------------------------------------------------------------------------------------------------"

        export SCRIPT_PATH=$(pwd)

        echo "---------------------------------------------------------------------------------------------------------------------------"
        echo " Create Config Directory"
          rm -r $INSTALL_PATH/* 
          mkdir -p $INSTALL_PATH 
          cd $INSTALL_PATH
        echo "    ${GREEN}  OK${NC}"
        echo "  "

        echo "---------------------------------------------------------------------------------------------------------------------------"
        echo " Gettting Installer"
        wget https://releases.ansible.com/ansible-tower/setup_openshift/ansible-tower-openshift-setup-3.6.3.tar.gz
        tar xvf ansible-tower-openshift-setup-3.6.3.tar.gz
        cd ansible-tower-openshift-setup-3.6.3

echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${CYAN}Adapt inventory file${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"



        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Backup vanilla inventory
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        cp inventory inventory.vanilla
        cp $SCRIPT_PATH/tools/ansible_tower/inventory ./inventory

        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Adapt inventory FIle
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${GREEN}Adapt Adapt Inventory File${NC}"


        ${SED} -i "s/my-ansible-host-ip/$MASTER_COMPONENTS/" inventory

        ${SED} -i "s/admin_user=admin/admin_user=admin/" inventory
        ${SED} -i "s/admin_password=''/admin_password='passw0rd'/" inventory
        ${SED} -i "s/secret_key=''/secret_key='mysupersecretkey'/" inventory
        ${SED} -i "s/pg_username=''/pg_username='pguser'/" inventory
        ${SED} -i "s/pg_password=''/pg_password='passw0rd'/" inventory
        ${SED} -i "s/rabbitmq_password=''/rabbitmq_password='passw0rd'/" inventory
        ${SED} -i "s/rabbitmq_cookie=''/rabbitmq_cookie='rabbitmqcookie'/" inventory


        echo "openshift_pg_emptydir=true"  >> inventory
        echo "openshift_host=https://$CLUSTER_NAME"  >> inventory
        echo "openshift_project=ansible-tower"  >> inventory
        echo "openshift_user=admin"  >> inventory
        echo "openshift_password=passw0rd"  >> inventory


echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "





echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${GREEN}Current inventory file for installation${NC}"
echo " ${GREEN}Please Check if it looks OK${NC}"
echo " ${ORANGE}vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv${NC}"
echo "  "
        cat inventory
echo "  "
echo " ${ORANGE}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^${NC}"
echo " ${GREEN}Current inventory file for installation${NC}"
echo " ${GREEN}Please Check if it looks OK${NC}"
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
echo " ${ORANGE}Do you want to install Ansible Tower into Cluster '$CLUSTER_NAME' with the above configuration?${NC}"
echo ""
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"

read -p "Install? [y,N]" DO_COMM
if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then

    setup_openshift.sh
  
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""

else
    echo "${RED}Installation Aborted${NC}"
fi



echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN} Ansible Tower Installation.... DONE${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"


