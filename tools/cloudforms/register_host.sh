
echo "    Copy Cert"
cp /root/ibm-mcm-ca.crt /etc/pki/ca-trust/source/anchors/ibm-mcm-ca.crt
echo "       OK"


echo "    Update trust"
update-ca-trust
echo "       OK"

echo "    Restart evmserverd"
systemctl restart evmserverd
echo "       OK"

echo "    Get Template Dir"
TEMPLATE_DIR="/opt/rh/cfme-appliance/TEMPLATE"
echo "       OK"

echo "    Copy Template"
cp ${TEMPLATE_DIR}/etc/httpd/conf.d/manageiq-remote-user-openidc.conf \
/etc/httpd/conf.d/
echo "       OK"

echo "    Copy Template"
cp ${TEMPLATE_DIR}/etc/httpd/conf.d/manageiq-external-auth-openidc.conf.erb \
/etc/httpd/conf.d/manageiq-external-auth-openidc.conf
echo "      OK"


echo "    Copy opeidc config"
cp /root/manageiq-external-auth-openidc.conf /etc/httpd/conf.d/manageiq-external-auth-openidc.conf
echo "       OK"


echo "    Restart httpd"
systemctl restart httpd
echo "       OK"

echo "Done"
