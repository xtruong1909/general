#!/bin/bash

execute_with_prompt() {
    echo "Executing: $1"
    if eval "$1"; then
        echo "Command executed successfully."
    else
        echo "Error executing command: $1"
        exit 1
    fi
}
cd allora-chain/
git clone -b worker-face-10m https://github.com/nhunamit/basic-coin-prediction-node worker-face-10m
cd worker-face-10m/
mkdir -p worker-topic-2-data
chmod 777 worker-topic-2-data


echo "This is your Head ID:"
HEAD_ID=$(cat head-data/keys/identity)
echo "$HEAD_ID"
echo

if [ -f docker-compose.yml ]; then
    rm docker-compose.yml
    echo "Removed existing docker-compose.yml file."
    echo
fi

read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE
echo

echo "Generating docker-compose.yml file..."
cat <<EOF > docker-compose.yml
version: '3'

services:
  inference:
    container_name: net1-worker2-inference
    build:
      context: .
    command: python -u /app/app.py
    ports:
      - "8011:8011"
    networks:
      net1-worker2:
        aliases:
          - inference
        ipv4_address: 172.32.0.2
    healthcheck:
      # test: ["CMD", "curl", "-f", "http://localhost:8011/inference/ETH"]
      test: ["CMD-SHELL", "curl -f http://localhost:8011/inference/ETH || exit 1 && curl -f http://localhost:8011/inference/BTC || exit 1 && curl -f http://localhost:8011/inference/SOL || exit 1"]
      interval: 10s
      timeout: 20s
      retries: 12
      start_period: 600s
    volumes:
      - ./inference-data:/app/data
  
  updater:
    container_name: net1-updater2
    build: .
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8011
    command: >
      sh -c "
      while true; do
        python -u /app/update_app.py;
        sleep 300;  # 300 seconds (5 minutes)
      done
      "
    depends_on:
      inference:
        condition: service_healthy
    networks:
      net1-worker2:
        aliases:
          - updater
        ipv4_address: 172.32.0.3
    
  worker_topic_2:
    container_name: net1-worker2-topic-2
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8011
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9102 \
          --boot-nodes=/dns4/head-0-p2p.edgenet.allora.network/tcp/32067/p2p/12D3KooWNiJ9KPtBwCSzbuvXL544U9FtWwvbLUH2VJcv1HyFMxj1,/dns4/head-0-p2p.edgenet.allora.network/tcp/32067/p2p/12D3KooWNiJ9KPtBwCSzbuvXL544U9FtWwvbLUH2VJcv1HyFMxj1,/dns4/head-1-p2p.edgenet.allora.network/tcp/32061/p2p/12D3KooWMbXijKMcsJfeBGkPavq5Q3Mh7m83DUvd8CHVDUKbpXDa,/dns4/head-2-p2p.edgenet.allora.network/tcp/32069/p2p/12D3KooWN3zVFkEDDH1DGJGHmJDZnB6ghhhKDz4Vzat6Z6P5i9y5 \
          --topic=allora-topic-2-worker \
          --allora-chain-key-name=net1_worker \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-chain-topic-id=2 \
          --allora-node-rpc-address=https://allora-rpc.edgenet.allora.network \
          --allora-chain-worker-mode=worker
    volumes:
      - ./worker-topic-2-data:/data
    working_dir: /data
    depends_on:
      - inference
    ports:
      - "9102:9102"
    networks:
      net1-worker2:
        aliases:
          - worker_topic_2
        ipv4_address: 172.32.0.21

  
networks:
  net1-worker2:
    driver: bridge
    ipam:
      config:
        - subnet: 172.32.0.0/24
EOF

echo "docker-compose.yml file generated successfully!"
echo

echo "Building and starting Docker containers..."
docker-compose build
docker-compose up -d
echo

echo "Checking running Docker containers..."
docker ps
