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

echo "Installing packages..."
execute_with_prompt "sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc unzip lz4 python3 python3-pip -y"
echo

echo "Installing Docker..."
execute_with_prompt 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
execute_with_prompt 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
execute_with_prompt 'sudo apt-get update'
execute_with_prompt 'sudo apt-get install docker-ce docker-ce-cli containerd.io -y'
echo

echo "Checking docker version..."
execute_with_prompt 'docker version'
echo

echo "Installing Docker Compose..."
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
execute_with_prompt 'sudo curl -L "https://github.com/docker/compose/releases/download/'"$VER"'/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose'
execute_with_prompt 'sudo chmod +x /usr/local/bin/docker-compose'
echo

echo "Checking docker-compose version..."
execute_with_prompt 'docker-compose --version'
echo

if ! grep -q '^docker:' /etc/group; then
    execute_with_prompt 'sudo groupadd docker'
fi

execute_with_prompt 'sudo usermod -aG docker $USER'
echo

echo "Checking if Go is installed..."
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Installing Go..."
    execute_with_prompt 'sudo rm -rf /usr/local/go && sudo snap install go --classic'
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
    echo 'export GONOSUMDB="*"' >> ~/.bashrc
    echo 'export GONOPROXY="*"' >> ~/.bashrc
    echo 'export GOPROXY="https://goproxy.io,direct"' >> ~/.bashrc
    execute_with_prompt 'source ~/.bashrc'
else
    echo "Go is already installed. Skipping installation."
fi
echo

echo "Checking go version..."
execute_with_prompt 'go version'
echo

echo "Installing Allorand..."
git clone https://github.com/allora-network/allora-chain.git
cd allora-chain && make all
echo

echo "Checking allorand version..."
execute_with_prompt 'allorad version'
echo

echo "Importing wallet..."
execute_with_prompt 'allorad keys add testkey --recover'
echo

echo "Installing worker node..."
git clone https://github.com/allora-network/basic-coin-prediction-node
cd basic-coin-prediction-node
mkdir worker-data
mkdir head-data
echo

echo "Giving permissions..."
execute_with_prompt 'sudo chmod -R 777 worker-data head-data'
echo

echo "Creating Head keys..."
echo
execute_with_prompt 'sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"'
echo
execute_with_prompt 'sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"'
echo

echo "This is your Head ID:"
cat head-data/keys/identity
echo

if [ -f docker-compose.yml ]; then
    execute_with_prompt 'rm docker-compose.yml'
    echo "Removed existing docker-compose.yml file."
    echo
fi

read -p "Enter HEAD_ID: " HEAD_ID
echo

read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE
echo

echo "Generating docker-compose.yml file..."
cat <<EOF > docker-compose.yml
version: '3'
services:
  inference:
    container_name: inference-basic-eth-pred
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
    volumes:
      - ./inference-data:/app/data

  updater:
    container_name: updater-basic-eth-pred
    build: .
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
    command: >
      sh -c "
      while true; do
        python -u /app/update_app.py;
        sleep 24h;
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

  worker:
    container_name: worker-basic-eth-pred
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
          --allora-node-rpc-address=https://allora-rpc.edgenet.allora.network/ \
          --allora-chain-topic-id=1
    volumes:
      - ./worker-data:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker
        ipv4_address: 172.22.0.10

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
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=head --peer-db=/data/peerdb --function-db=/data/function-db  \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9010 --rest-api=:6000
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

echo "docker-compose.yml file generated successfully!"
echo

echo "Building and starting Docker containers..."
execute_with_prompt 'docker-compose build'
execute_with_prompt 'docker-compose up -d'
echo

echo "Checking running Docker containers..."
execute_with_prompt 'docker ps'
