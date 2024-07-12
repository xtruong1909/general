#!/bin/bash

# Colour ANSI
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# Function to execute commands with error handling
execute_with_prompt() {
    echo "Executing: $1"
    if eval "$1"; then
        echo "Command executed successfully."
    else
        echo "Error executing command: $1"
        exit 1
    fi
}

# Run the curl command and capture the output
response=$(curl -s --location 'http://localhost:6000/api/v1/functions/execute' \
--header 'Content-Type: application/json' \
--data '{
    "function_id": "bafybeigpiwl3o73zvvl6dxdqu7zqcub5mhg65jiky2xqb4rdhfmikswzqm",
    "method": "allora-inference-function.wasm",
    "parameters": null,
    "topic": "1",
    "config": {
        "env_vars": [
            {
                "name": "BLS_REQUEST_PATH",
                "value": "/api"
            },
            {
                "name": "ALLORA_ARG_PARAMS",
                "value": "ETH"
            }
        ],
        "number_of_nodes": -1,
        "timeout": 2
    }
}')

# Check if the curl command returned a code 200
if echo "$response" | grep -q '"code":"200"'; then
    echo -e "${GREEN}ALLORA WORKER NODE code 200:${NC}"
else
    echo -e "${YELLOW}ALLORA WORKER NODE error - REBUILD...:${NC}"

    # Perform Docker rebuild commands
    execute_with_prompt "cd $HOME/allora-chain/basic-coin-prediction-node"
    execute_with_prompt 'docker-compose build'
    execute_with_prompt 'docker-compose down'
    execute_with_prompt 'docker-compose up -d'
fi

echo -e "${GREEN}Finish:${NC}"
