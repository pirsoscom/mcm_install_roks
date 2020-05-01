# Install Script for IBM Cloud Pack for Multicloud Management on IBM ROKS Cloud

```
./2_install_mcm.sh -t MY_TOKEN -d /tmp/mcm-install -p passw0rd
./3_install_cam.sh -t MY_TOKEN -d /tmp/mcm-install -x console-openshift-console -p passw0rd
./4_install_apm.sh -t MY_TOKEN -d /tmp/mcm-install -x console-openshift-console -p passw0rd

./6_integrate_cloudforms.sh -d /Users/nhirt/TEMP/mcm-install -x console-openshift-console -p passw0rd -i w.x.y.z

./8_install_ldap.sh -d /tmp/mcm-install -x console-openshift-console -p passw0rd

./9_register_k8_monitor.sh -d niklaushirt -n mcm-hub -f /Users/nhirt/ibm-cloud-apm-dc-configpack_CP4MCM002.tar


kubectl apply -f tools/apm/kubetoy_all_in_one.yaml -n default


OPENLDAP
dc=local,dc=io
cn=admin,dc=local,dc=io
passw0rd
ldap://openldap.default:389

```