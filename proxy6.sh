# IPv6 Proxy Configuration
dns_v4_first off
dns_nameservers 2001:4860:4860::8888 2001:4860:4860::8844

auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/squid_passwd
auth_param basic realm Proxy Authentication
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all

cache deny all
forwarded_for off
via off
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access X-Real-IP deny all

access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
pid_filename /var/run/squid.pid

http_port [::]:33333 name=mainport
acl mainport myportname mainport
tcp_outgoing_address 2401:1960:0:82a3::1 mainport
root@h01-43802:~# curl -6 --proxy http://USERNAME:PASSWORD@[2401:1960:0:82a3::1]:33333 https://telegram.org
curl: (56) Received HTTP code 407 from proxy after CONNECT
root@h01-43802:~# nano ipv6.sh
root@h01-43802:~# bash ipv6.sh 
=== Tạo proxy IPv6 từ địa chỉ hiện có trên eth0 ===
→ Đang tìm địa chỉ IPv6...
✅ Tìm thấy IPv6: 2401:1960:0:82a3::1
→ Đang tạo cấu hình Squid tại /etc/squid/squid.conf...
→ Tạo user Squid proxy...
Adding password for user airdrop2024
→ Restart dịch vụ Squid...
✅ Squid đang chạy
→ Lưu danh sách proxy...

✅ Proxy đã sẵn sàng!
→ IP: [2401:1960:0:82a3::1]
→ Port: 3128
→ Username: airdrop2024
→ Password: Myproxy2024
→ File:
   - proxy_list.txt
   - proxy_list_curl.txt
   - proxy_endpoints.txt
root@h01-43802:~# cat proxy
cat: proxy: No such file or directory
root@h01-43802:~# cat proxy.t
cat: proxy.t: No such file or directory
root@h01-43802:~# cat proxy_list.txt 
[2401:1960:0:82a3::1]:3128:airdrop2024:Myproxy2024
root@h01-43802:~# cat proxy6.sh 
#!/bin/bash
SQUID_CONF="/etc/squid/squid.conf"
PASSWD_FILE="/etc/squid/squid_passwd"
INTERFACE="eth0"

echo "=== Tạo proxy IPv6 từ địa chỉ hiện có trên $INTERFACE ==="

# Lấy IPv6 hợp lệ (loại bỏ link-local)
echo "→ Đang tìm địa chỉ IPv6..."
IPV6=$(ip -6 addr show dev "$INTERFACE" scope global | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n1)

if [[ -z "$IPV6" ]]; then
    echo "Không tìm thấy địa chỉ IPv6 hợp lệ trên $INTERFACE!"
    exit 1
fi

echo "Tìm thấy IPv6: $IPV6"

# Tạo cấu hình Squid
echo "→ Đang tạo cấu hình Squid tại $SQUID_CONF..."

mkdir -p /var/log/squid

cat > "$SQUID_CONF" <<EOF
# IPv6 Proxy Configuration
dns_v4_first off
dns_nameservers 2001:4860:4860::8888 2001:4860:4860::8844

auth_param basic program /usr/lib/squid/basic_ncsa_auth $PASSWD_FILE
auth_param basic realm Proxy Authentication
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all

cache deny all
forwarded_for off
via off
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access X-Real-IP deny all

access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
pid_filename /var/run/squid.pid

http_port [::]:$PORT name=mainport
acl mainport myportname mainport
tcp_outgoing_address $IPV6 mainport
EOF

# Tạo user/password proxy
echo "→ Tạo user Squid proxy..."
htpasswd -bc "$PASSWD_FILE" "$USERNAME" "$PASSWORD"

# Restart Squid
echo "→ Restart dịch vụ Squid..."
systemctl restart squid
sleep 2

# Kiểm tra Squid hoạt động
if systemctl is-active --quiet squid; then
    echo "Squid đang chạy"
else
    echo "Squid không khởi động được. Kiểm tra log:"
    journalctl -u squid --no-pager -n 20
    exit 1
fi

# Lưu file thông tin proxy
echo "→ Lưu danh sách proxy..."

echo "[$IPV6]:$PORT:$USERNAME:$PASSWORD" > ./proxy_list.txt
echo "[$IPV6]:$PORT" > ./proxy_list_curl.txt
cat > ./proxy_endpoints.txt <<EOF
# Test proxy:
curl --proxy http://$USERNAME:$PASSWORD@[$IPV6]:$PORT http://ipv6.icanhazip.com
EOF

#Finish
echo
echo "Proxy đã sẵn sàng!"
echo "$(curl -4 -s ifconfig.me):$PORT:$USERNAME:$PASSWORD"
echo
echo "→ File:"
echo "   - proxy_list.txt"
echo "   - proxy_list_curl.txt"
echo "   - proxy_endpoints.txt"
