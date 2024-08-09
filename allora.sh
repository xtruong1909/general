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
read -p "Enter ALLORA_ADDRESS: " ALLORA_ADDRESS

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
    volumes:
      - ./worker-data:/data1
    depends_on:
      inference:
        condition: service_healthy
    environment:
      ALLORA_OFFCHAIN_NODE_CONFIG_JSON: >
        {"wallet":{"addressKeyName":"basic-coin-prediction-offchain-node","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","addressAccountPassphrase":"secret","alloraHomeDir":"","gas":"1000000","gasAdjustment":1,"nodeRpc":"https://allora-rpc.devnet.behindthecurtain.xyz","maxRetries":1,"minDelay":1,"maxDelay":2,"submitTx":false},"worker":[{"topicId":1,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      ALLORA_OFFCHAIN_ACCOUNT_ADDRESS: '$ALLORA_ADDRESS'
      NAME: basic-coin-prediction-offchain-node
      ENV_LOADED: 'true'

  worker2:
    container_name: worker2
    image: alloranetwork/allora-offchain-node:latest
    volumes:
      - ./worker-data:/data2
    depends_on:
      inference:
        condition: service_healthy
    environment:
      ALLORA_OFFCHAIN_NODE_CONFIG_JSON: >
        {"wallet":{"addressKeyName":"basic-coin-prediction-offchain-node","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","addressAccountPassphrase":"secret","alloraHomeDir":"","gas":"1000000","gasAdjustment":1,"nodeRpc":"https://allora-rpc.devnet.behindthecurtain.xyz","maxRetries":1,"minDelay":1,"maxDelay":2,"submitTx":false},"worker":[{"topicId":2,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      ALLORA_OFFCHAIN_ACCOUNT_ADDRESS: '$ALLORA_ADDRESS'
      NAME: basic-coin-prediction-offchain-node
      ENV_LOADED: 'true'

  worker7:
    container_name: worker7
    image: alloranetwork/allora-offchain-node:latest
    volumes:
      - ./worker-data:/data7
    depends_on:
      inference:
        condition: service_healthy
    environment:
      ALLORA_OFFCHAIN_NODE_CONFIG_JSON: >
        {"wallet":{"addressKeyName":"basic-coin-prediction-offchain-node","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","addressAccountPassphrase":"secret","alloraHomeDir":"","gas":"1000000","gasAdjustment":1,"nodeRpc":"https://allora-rpc.devnet.behindthecurtain.xyz","maxRetries":1,"minDelay":1,"maxDelay":2,"submitTx":false},"worker":[{"topicId":7,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      ALLORA_OFFCHAIN_ACCOUNT_ADDRESS: '$ALLORA_ADDRESS'
      NAME: basic-coin-prediction-offchain-node
      ENV_LOADED: 'true'

volumes:
  inference-data:
  worker-data:
EOF

echo "docker-compose.yml file generated successfully."
echo "Starting Docker containers..."
execute_with_prompt "docker-compose up -d"

echo "Setup completed."
