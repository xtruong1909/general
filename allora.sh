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

cd
cd basic-coin-prediction-node
mkdir head-data worker-data-1 worker-data-2 worker-data-7 worker-data-11
sudo chmod -R 777 head-data worker-data-1 worker-data-2 worker-data-7 worker-data-11

sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-1:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-2:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-7:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-11:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"



echo "This is your Head ID:"
HEAD_ID=$(cat head-data/keys/identity)
echo "$HEAD_ID"

if [ -f docker-compose.yml ]; then
    rm docker-compose.yml
    echo "Removed existing docker-compose.yml file."
    echo
fi

echo "This is your Head ID:"
HEAD_ID=$(cat head-data/keys/identity)
echo "$HEAD_ID"

if [ -f docker-compose.yml ]; then
    rm docker-compose.yml
    echo "Removed existing docker-compose.yml file."
    echo
fi

read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE

echo "Generating docker-compose.yml file..."
cat <<EOF > docker-compose.yml
version: '3'
services:
  inference:
    container_name: inference
    build:
      context: .
    command: python -u /app/app.py
    ports:
      - "8000:8000"
    networks:
      eth-model-local:
        aliases:
          - inference
        ipv4_address: 172.22.0.4
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/inference/ETH"]
      interval: 10s
      timeout: 10s
      retries: 12
      start_period: 60s
    volumes:
      - ./inference-data:/app/data
    restart: always


  updater:
    container_name: updater
    build: .
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
    command: >
      sh -c "
      while true; do
        python -u /app/update_app.py;
        sleep 600;
      done
      "
    depends_on:
      inference:
        condition: service_healthy
    networks:
      eth-model-local:
        aliases:
          - updater
        ipv4_address: 172.22.0.5
    restart: always


  worker-1:
    container_name: worker-1
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
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
          --private-key=/data/keys/priv.bin --log-level=debug --port=9011 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$HEAD_ID \
          --topic=allora-topic-1-worker \
          --allora-chain-key-name=testkey \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=1 \
          --allora-chain-initial-stake=1000 \
          --allora-chain-worker-mode=worker

    volumes:
      - ./worker-data-1:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-1
        ipv4_address: 172.22.0.11
    restart: always


  worker-2:
    container_name: worker-2
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
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
          --private-key=/data/keys/priv.bin --log-level=debug --port=9012 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$HEAD_ID \
          --topic=allora-topic-2-worker \
          --allora-chain-key-name=testkey \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=2 \
          --allora-chain-initial-stake=1000 \
          --allora-chain-worker-mode=worker

    volumes:
      - ./worker-data-2:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-2
        ipv4_address: 172.22.0.12
    restart: always


  worker-7:
    container_name: worker-7
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
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
          --private-key=/data/keys/priv.bin --log-level=debug --port=9017 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$HEAD_ID \
          --topic=allora-topic-7-worker \
          --allora-chain-key-name=testkey \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=7 \
          --allora-chain-initial-stake=1000 \
          --allora-chain-worker-mode=worker

    volumes:
      - ./worker-data-7:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-7
        ipv4_address: 172.22.0.17
    restart: always


  worker-11:
    container_name: worker-11
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
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
          --private-key=/data/keys/priv.bin --log-level=debug --port=9021 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$HEAD_ID \
          --topic=allora-topic-11-worker \
          --allora-chain-key-name=testkey \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=11 \
          --allora-chain-initial-stake=1000 \
          --allora-chain-worker-mode=worker

    volumes:
      - ./worker-data-11:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-11
        ipv4_address: 172.22.0.21
    restart: always


  head:
    container_name: head
    image: alloranetwork/allora-inference-base-head:latest
    environment:
      - HOME=/data
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
        allora-node --role=head --peer-db=/data/peerdb --function-db=/data/function-db  \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9010 --rest-api=:6000 \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-chain-initial-stake=1000
    ports:
      - "6000:6000"
    volumes:
      - ./head-data:/data
    working_dir: /data
    networks:
      eth-model-local:
        aliases:
          - head
        ipv4_address: 172.22.0.100
    restart: always


networks:
  eth-model-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/16
EOF

echo "docker-compose.yml file generated successfully."
echo "Starting Docker containers..."
execute_with_prompt "docker-compose up -d"

echo "Setup completed."
