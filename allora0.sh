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

echo "Installing packages..."
execute_with_prompt "sudo apt install make jq build-essential gcc python3 python3-pip docker.io docker-compose -y"
execute_with_prompt 'sudo snap install go --classic'
    echo 'export PATH=$PATH:/usr/local/go/bin:$(go env GOPATH)/bin' >> ~/.profile && source ~/.profile
echo

if ! grep -q '^docker:' /etc/group; then
    execute_with_prompt 'sudo groupadd docker'
fi

execute_with_prompt 'sudo usermod -aG docker $USER'
echo

echo "Installing Allorand..."
git clone https://github.com/allora-network/allora-chain.git
cd allora-chain && git checkout v0.0.10 && make install
echo

echo "Checking allorand version..."
allorad version
echo

echo "Importing wallet..."
allorad keys add testkey --recover
echo

echo "Installing worker node..."
git clone https://github.com/allora-network/basic-coin-prediction-node
cd basic-coin-prediction-node
mkdir worker-data
mkdir head-data
echo

echo "Giving permissions..."
sudo chmod -R 777 worker-data head-data
echo
