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
cd allora-chain/basic-coin-prediction-node2/
mkdir worker-data
mkdir head-data
echo
echo "Creating Head keys..."
echo
sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
echo
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
echo

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
    container_name: inference-basic-eth-pred2
    build:
      context: .
    command: python -u /app/app.py
    ports:
      - "8050:8050"
    networks:
      eth-model-local:
        aliases:
          - inference
        ipv4_address: 172.25.0.4
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8050/inference/ETH"]
      interval: 10s
      timeout: 10s
      retries: 12
    volumes:
      - ./inference-data:/app/data
    restart: always

  updater:
    container_name: updater-basic-eth-pred2
    build: .
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8050
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
        ipv4_address: 172.25.0.5
    restart: always

  worker:
    container_name: worker-basic-eth-pred2
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8050
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
          --private-key=/data/keys/priv.bin --log-level=debug --port=9051 \
          --boot-nodes=/ip4/172.25.0.100/tcp/9050/p2p/$HEAD_ID \
          --topic=allora-topic-1-worker \
          --allora-chain-key-name=testkey \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.edgenet.allora.network/ \
          --allora-chain-topic-id=2
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
        ipv4_address: 172.25.0.10
    restart: always

  head:
    container_name: head-basic-eth-pred2
    image: alloranetwork/allora-inference-base-head2:latest
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
          --private-key=/data/keys/priv.bin --log-level=debug --port=9050 --rest-api=:6050
    ports:
      - "6050:6050"
    volumes:
      - ./head-data:/data
    working_dir: /data
    networks:
      eth-model-local:
        aliases:
          - head
        ipv4_address: 172.25.0.100
    restart: always

networks:
  eth-model-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.25.0.0/24

volumes:
  inference-data:
  worker-data:
  head-data:
EOF

echo "docker-compose.yml file generated successfully!"
echo

echo "Building and starting Docker containers..."
docker-compose build
docker-compose up -d
echo

echo "Checking running Docker containers..."
docker ps
