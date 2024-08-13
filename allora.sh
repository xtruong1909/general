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
cd basic-coin-prediction-node/worker-data
mkdir data1 data2 data7
sudo chmod -R 777 data1 data2 data7
cd && cd basic-coin-prediction-node

# sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-1:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-2:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-7:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data-11:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"



read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE

echo "Generating docker-compose.yml file..."
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  inference:
    container_name: inference-basic-eth-pred
    build: .
    command: python -u /app/app.py
    ports:
      - "8000:8000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/inference/ETH"]
      interval: 10s
      timeout: 5s
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

  worker1:
    container_name: worker1
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"1000000","gasAdjustment":1.0,"nodeRpc":"https://sentries-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":1,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      - NAME=test-worker1
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy

  worker2:
    container_name: worker2
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"1000000","gasAdjustment":1.0,"nodeRpc":"https://sentries-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":2,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      - NAME=test-worker2
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy

  worker3:
    container_name: worker3
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"1000000","gasAdjustment":1.0,"nodeRpc":"https://sentries-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":3,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"BTC"}}]}
      - NAME=test-worker1
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy

  worker7:
    container_name: worker7
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"1000000","gasAdjustment":1.0,"nodeRpc":"https://sentries-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":7,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      - NAME=test-worker7
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy

volumes:
  inference-data:
  worker-data:

EOF

echo "docker-compose.yml file generated successfully."
echo "Starting Docker containers..."
execute_with_prompt "docker-compose up -d"

echo "Setup completed."
