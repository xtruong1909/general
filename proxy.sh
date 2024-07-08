#!/bin/bash

sudo apt install squid -y
sudo apt-get install apache2-utils -y
sudo rm /etc/squid/squid.conf

# Tao tap tin cau hinh Squid moi
sudo bash -c 'cat << EOF > /etc/squid/squid.conf
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
# Choose the port you want. Default: 3128.
http_port 31288
EOF'

# Tao mat khau
USERNAME=airdr2024money
PASSWORD=3trieuDolla2024
sudo htpasswd -b -c /etc/squid/passwords $USERNAME $PASSWORD

# Khoi dong lai squid
sudo systemctl restart squid.service

echo "Finish."
