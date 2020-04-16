# Install Scripts for IBM Cloud Pack for Multicloud Management

```
./2_install_mcm.sh -t MY_TOKEN -d MY-PATH/mcm-install -p passw0rd
./3_install_cam.sh -t MY_TOKEN -d MY-PATH/mcm-install -x console-openshift-console -p passw0rd
./4_install_apm.sh -t MY_TOKEN -d MY-PATH/mcm-install -x console-openshift-console -p passw0rd

./8_install_ldap.sh -d MY-PATH/mcm-install -x console-openshift-console -p passw0rd
./9_register_k8_monitor.sh -d MY-DOCKERGROUP -n test-cluster -f MY-CONFIG-PATH/ibm-cloud-apm-dc-configpack.tar

```