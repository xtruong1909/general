#!/bin/bash

cd && cd basic-coin-prediction-node
read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE

echo "Generating docker-compose.yml file..."
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  inference:
    container_name: inference
    build:
      context: .
    command: python -u /app/app.py
    environment:
      - API_PORT=8000
    ports:
      - "8000:8000"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/inference/ETH || exit 1 && curl -f http://localhost:8000/inference/BTC || exit 1 && curl -f http://localhost:8000/inference/SOL || exit 1 && curl -f http://localhost:8000/inference/BNB || exit 1 && curl -f http://localhost:8000/inference/ARB || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 12
      start_period: 300s
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
        sleep 300;  # 300 seconds (5 minutes)
      done
      "
    depends_on:
      inference:
        condition: service_healthy
    restart: always


  worker1:
    container_name: worker1
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":1,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      - NAME=test
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always    

  worker2:
    container_name: worker2
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":2,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      - NAME=test
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always     
    
  worker3:
    container_name: worker3
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":3,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"BTC"}}]}
      - NAME=test
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always    

  worker4:
    container_name: worker4
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":4,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"BTC"}}]}
      - NAME=test
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always      

  worker5:
    container_name: worker5
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":5,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"SOL"}}]}
      - NAME=test
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always   

  worker6:
    container_name: worker6
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":6,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"SOL"}}]}
      - NAME=test
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always       
    
  worker7:
    container_name: worker7
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":7,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ETH"}}]}
      - NAME=test-worker7
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always

  worker8:
    container_name: worker8
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":8,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"BNB"}}]}
      - NAME=test-worker7
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always    

  worker9:
    container_name: worker9
    image: alloranetwork/allora-offchain-node:latest
    environment:
      - ALLORA_OFFCHAIN_NODE_CONFIG_JSON={"wallet":{"addressKeyName":"test","addressRestoreMnemonic":"$WALLET_SEED_PHRASE","alloraHomeDir":"","gas":"5000000","gasAdjustment":1.2,"nodeRpc":"https://allora-rpc.testnet-1.testnet.allora.network","maxRetries":1,"delay":1,"submitTx":false},"worker":[{"topicId":9,"inferenceEntrypointName":"api-worker-reputer","loopSeconds":5,"parameters":{"InferenceEndpoint":"http://inference:8000/inference/{Token}","Token":"ARB"}}]}
      - NAME=test-worker7
      - ENV_LOADED=true
    volumes:
      - ./worker-data:/data
    depends_on:
      inference:
        condition: service_healthy
    restart: always    
    
volumes:
  inference-data:
  worker-data:

EOF

execute_with_prompt "docker-compose up -d"

