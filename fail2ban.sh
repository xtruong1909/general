#!/bin/bash
sudo apt install fail2ban -y

# Tạo và chỉnh sửa cấu hình jail.local
echo "Configuring fail2ban for VNC..."
sudo bash -c 'cat > /etc/fail2ban/jail.local' <<EOL
[vnc-attack]
enabled = true
port = 7000
filter = vnc-auth
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOL

# Tạo và chỉnh sửa file filter vnc-auth.conf
echo "Creating VNC filter..."
sudo bash -c 'cat > /etc/fail2ban/filter.d/vnc-auth.conf' <<EOL
[Definition]
failregex = .*VNC authentication failure from <HOST>.*
ignoreregex =
EOL

# Khởi động lại fail2ban
echo "Restarting fail2ban service..."
sudo systemctl restart fail2ban

echo "Fail2ban setup for VNC completed!"
