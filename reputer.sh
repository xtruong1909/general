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
cd coin-prediction-reputer
mkdir worker-data truth-data
sudo chmod -R 777 worker-data truth-data


read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE

echo "Generating docker-compose.yml file..."
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  truth:
    build: .
    command: python -u /app/app.py
    environment:
      - DATABASE_PATH=/app/data/prices.db
      - API_PORT=8000
      - ALLORA_VALIDATOR_API_URL=https://sentries-api.testnet-1.testnet.allora.network/
      - TOKEN=ETH
      - TOKEN_CG_ID=ethereum
    ports:
      - "8001:8000"
    volumes:
      - ./truth-data:/app/data

  updater:
    container_name: update
    build: .
    depends_on:
      - truth
    entrypoint: ["sh", "-c", "while true; sleep 60; do python -u /app/update_app.py; done"]
    environment:
      - DATA_PROVIDER_API_ADDRESS=http://truth:8000

  reputer:
    container_name: reputer
    image: alloranetwork/allora-offchain-node:latest
    volumes:
      - ./worker-data:/data
    depends_on:
      - truth
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"1000000","gasAdjustment":1.0,"nodeRpc":"https://sentries-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"reputer":[{"topicId":1,"reputerEntrypointName":"api-worker-reputer","loopSeconds":30,"minStake":100000,"parameters":{"SourceOfTruthEndpoint":"http://truth:8000/gt/{Token}/{BlockHeight}","Token":"ETHUSD"}}]}
      - NAME=test
      - ENV_LOADED=true

volumes:
  worker-data:
  truth-data:

EOF

echo "docker-compose.yml file generated successfully."
echo "Starting Docker containers..."
execute_with_prompt "docker-compose up -d"

echo "Setup completed."
