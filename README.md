# Openshift Installation on Baremetal
- this repo contains all the config files and bash script for installer provisioned setup of openshift container platform on baremetal
- the basis for the config-files and the preparation steps were taken from: https://github.com/ryanhay/ocp4-metal-install.git

# Download Files from Red Hat Cluster Manager
https://console.redhat.com/openshift
- Create Cluster | Datacenter | Bare Metal (x86_64) | User-provisioned Infrastructure
  - Download installer
  - Download pull secret
  - Download command-line tools

# copy files to Service-Node
- scp [path-to-downloaded-files] [username]@[ocp-svc_IP_address]:[/username/home/new-path]
- then ssh into the Service-Node: ssh [username]@[ocp-svc_IP_address]
- install git: dnf git -y
- clone this repo: git clone https://github.com/violets-are-vio/ocp-install-templates.git

# Prepare Service-Node
- make necessary changes to all config files. (check if the ip-addresses and hostnames are the same as yours)
  - first define your hostnames and adresses on dhcpd.conf
  - adjust in haproxy.cfg, named.conf, zones/db.ocp.lan, zones/db.reverse
  - run ssh-keygen, then add .ssh/id_rsa.pub and pull secret to install-config.yaml
- make bash script executable: chmod +x /ocp-install-templates/ocp-install-prep.sh
- run script: ./ocp-install-templates/ocp-install-prep.sh
