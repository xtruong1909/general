#!/bin/bash

# Cài đặt Squid và Apache2 utils
sudo apt install squid -y
sudo apt-get install apache2-utils -y

# Xóa tập tin cấu hình Squid cũ
sudo rm /etc/squid/squid.conf

# Tạo tập tin cấu hình Squid mới
sudo bash -c 'cat << EOF > /etc/squid/squid.conf
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
# Choose the port you want. Default: 3128.
http_port 3128
EOF'

# Tạo tệp mật khẩu và thêm người dùng
sudo htpasswd -c /etc/squid/passwords 8888

# Khởi động lại dịch vụ Squid
sudo systemctl restart squid.service

echo "Cấu hình Squid hoàn tất."
