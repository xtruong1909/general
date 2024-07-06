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

echo "Updating system dependencies..."
execute_with_prompt "sudo apt update -y && sudo apt upgrade -y"
echo

echo "Installing necessary packages..."
execute_with_prompt "sudo apt install -y ca-certificates curl git docker-compose python3 python3-pip"
echo

echo "Installing Go..."
execute_with_prompt 'wget "https://golang.org/dl/go1.21.3.linux-amd64.tar.gz"'
execute_with_prompt 'sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.21.3.linux-amd64.tar.gz'
execute_with_prompt 'rm go1.21.3.linux-amd64.tar.gz'
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc
echo

echo "Cloning and building Allorand..."
execute_with_prompt 'git clone https://github.com/allora-network/allora-chain.git'
execute_with_prompt 'cd allora-chain && make all'
echo

echo "Importing wallet..."
allorad keys add testkey --recover
echo

echo "Request faucet to your wallet from this link: https://faucet.edgenet.allora.network/"
echo

echo "Setting up worker node..."
git clone https://github.com/allora-network/basic-coin-prediction-node
cd basic-coin-prediction-node
mkdir worker-data head-data
sudo chmod -R 777 worker-data head-data
sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
echo

echo "Generating docker-compose.yml file..."
read -p "Enter HEAD_ID: " HEAD_ID
read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE

cat <<EOF > docker-compose.yml
version: '3'
services:
  inference:
    container_name: inference-basic-eth-pred
    build: .
    command: python -u /app/app.py
    ports:
      - "8000:8000"
    volumes:
      - ./inference-data:/app/data

  worker:
    container_name: worker-basic-eth-pred
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build: .
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          mkdir -p /data/keys && cd /data/keys && allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9011 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$HEAD_ID \
          --topic=allora-topic-1-worker \
          --allora-chain-key-name=testkey \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.edgenet.allora.network/ \
          --allora-chain-topic-id=1
    volumes:
      - ./worker-data:/data
    depends_on:
      - inference
      - head

  head:
    container_name: head-basic-eth-pred
    image: alloranetwork/allora-inference-base-head:latest
    environment:
      - HOME=/data
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          mkdir -p /data/keys && cd /data/keys && allora-keys
        fi
        allora-node --role=head --peer-db=/data/peerdb --function-db=/data/function-db  \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9010 --rest-api=:6000
    ports:
      - "6000:6000"
    volumes:
      - ./head-data:/data

networks:
  eth-model-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/24

volumes:
  inference-data:
  worker-data:
  head-data:
EOF

echo "Building and starting Docker containers..."
docker-compose build
docker-compose up -d
echo

echo "Checking running Docker containers..."
docker ps
