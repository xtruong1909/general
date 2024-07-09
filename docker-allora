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

echo "Rebuild docker"
execute_with_prompt "cd $HOME/allora-chain/basic-coin-prediction-node"
execute_with_prompt 'docker-compose build'
execute_with_prompt 'docker-compose down'
execute_with_prompt 'docker-compose up -d'
echo
