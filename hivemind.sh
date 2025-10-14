#!/bin/bash
set -e

apt update -y
apt install -y python3-pip python3-venv protobuf-compiler git golang curl
pip install --upgrade pip setuptools wheel
pip install grpcio grpcio-tools
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
cd
if [ ! -d "hivemind" ]; then
    git clone https://github.com/hiepntnaa/hivemind/
fi
cd hivemind
HIVEMIND_BUILDGO=1 pip install -e .
python3 -m grpc_tools.protoc -I hivemind/proto \
    --python_out=hivemind/proto \
    --grpc_python_out=hivemind/proto \
    hivemind/proto/*.proto
sed -i 's/^import \(.*_pb2\)/from hivemind.proto import \1/' hivemind/proto/*_pb2.py

# Get public IP
IP=$(curl -4 -s ifconfig.me)
cat > /root/hivemind/run_dht.py << EOF
from hivemind import DHT
import logging
import time

logging.basicConfig(level=logging.INFO)

host_maddrs = ['/ip4/0.0.0.0/tcp/40000']
announce_maddrs = ['/ip4/${IP}/tcp/40000']
identity_path = '/root/hivemind/identity.pem'

logging.info(f"Starting Hivemind DHT node...")
logging.info(f"Host addresses: {host_maddrs}")
logging.info(f"Announce addresses: {announce_maddrs}")

dht = DHT(
    start=True,
    host_maddrs=host_maddrs,
    announce_maddrs=announce_maddrs,
    identity_path=identity_path,  # File này nếu chưa có sẽ được tạo mới
    parallel_rpc=8,
)

logging.info("DHT node is running!")
logging.info(f"Peer ID: {dht.peer_id}")
logging.info(f"Visible addresses: {dht.get_visible_maddrs()}")

while True:
    time.sleep(3600)
EOF

echo "=== Creating systemd service..."
cat > /etc/systemd/system/hivemind.service << 'EOF'
[Unit]
Description=Hivemind Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/hivemind
ExecStart=/usr/bin/env PYTHONPATH=/root/hivemind /usr/bin/python3 /root/hivemind/run_dht.py
Restart=always
# Ghi log ra journalctl
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reloading and starting service..."
systemctl daemon-reload
systemctl enable hivemind
systemctl restart hivemind
echo "journalctl -u hivemind -f"
