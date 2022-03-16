#! /usr/bin/env bash

# install services
dnf update -y
dnf install bind bind-utils dhcp-server httpd haproxy nfs-utils -y

# extract client tools and copy them to /usr/local/bin
tar xvf openshift-client-linux.tar.gz
mv oc kubectl /usr/local/bin # verify this worked by trying 'kubectl version" and 'oc version'
tar xvf openshift-install-linux.tar.gz

# apply config that were pulled from git repository
\cp /home/$1/ocp-install-templates/config-files/named.conf /etc/named.conf
cp -R /home/$1/ocp-install-templates/config-files/zones /etc/named
\cp /home/$1/ocp-install-templates/config-files/dhcpd.conf /etc/dhcp/dhcpd.conf
\cp /home/$1/ocp-install-templates/config-files/haproxy.cfg /etc/haproxy/haproxy.cfg
mkdir /home/$1/ocp-install-files
cp /home/$1/ocp-install-templates/install-config.yaml /home/$1/ocp-install-files # edit pull-secret and ssh-file in install-config.yaml

# change default listen port to 8080 in httpd.conf
sed -i 's/Listen 80/Listen 0.0.0.0:8080/' /etc/httpd/conf/httpd.conf

# firewall configurations
nmcli connection modify ens192 connection.zone internal # ens192 = ethernet, if this is not yours, check running 'nmcli d'
firewall-cmd --zone=internal --add-masquerade --permanent
firewall-cmd --add-port=53/udp --zone=internal --permanent
firewall-cmd --add-port=53/tcp --zone=internal --permanent
firewall-cmd --add-service=dhcp --zone=internal --permanent
firewall-cmd --add-port=8080/tcp --zone=internal --permanent
firewall-cmd --add-port=6443/tcp --zone=internal --permanent # kube-api-server on control plane nodes
firewall-cmd --add-port=6443/tcp --zone=external --permanent # kube-api-server on control plane nodes
firewall-cmd --add-port=22624/tcp --zone=internal --permanent # machine-config server
firewall-cmd --add-service=http --zone=internal --permanent # web services hosted on worker nodes
firewall-cmd --add-service=http --zone=external --permanent # web services hosted on worker nodes
firewall-cmd --add-service=https --zone=internal --permanent # web services hosted on worker nodes
firewall-cmd --add-service=https --zone=external --permanent # web services hosted on worker nodes
firewall-cmd --add-port=9000/tcp --zone=external --permanent # HAProxy Stats
firewall-cmd --zone=internal --add-service mountd --permanent
firewall-cmd --zone=internal --add-service rpc-bind --permanent
firewall-cmd --zone=internal --add-service nfs --permanent
firewall-cmd --reload

# enable and start services
setsebool -P haproxy_connect_any 1 # SELinux name_bind access
systemctl enable named dhcpd httpd haproxy nfs-server rpcbind
systemctl start named dhcpd httpd haproxy nfs-server rpcbind nfs-mountd
systemctl restart NetworkManager

# create and export share
mkdir -p /shares/registry
chown -R nobody:nobody /shares/registry
chmod -R 777 /shares/registry
echo "/shares/registry  $2(rw,sync,root_squash,no_subtree_check,no_wdelay)" > /etc/exports # replace with your own subnet
exportfs -rv

# generate kubernetes manifest files
/home/$1/openshift-install create manifests --dir /home/$1/ocp-install-files

# generate ignition config and kubernetes auth files
/home/$1/openshift-install create ignition-configs --dir /home/$1/ocp-install-files

# create hosting directory for Openshift booting process
mkdir /var/www/html/ocp4

# copy all generated install files to the directory
cp -R /home/$1/ocp-install-files/* /var/www/html/ocp4

# change ownership and permissions
chcon -R -t httpd_sys_content_t /var/www/html/ocp4/
chown -R apache: /var/www/html/ocp4/
chmod 755 /var/www/html/ocp4/
echo $(curl localhost:8080/ocp4/) # confirm you can see all files added to the web server
