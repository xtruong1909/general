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

sudo apt install clang pkg-config libssl-dev protobuf-compiler bsdmainutils ncdu chrony liblz4-tool make jq build-essential gcc python3 python3-pip docker.io docker-compose -y
pip install --upgrade pip setuptools
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest

execute_with_prompt 'sudo snap install go --classic'
    echo 'export PATH=$PATH:/usr/local/go/bin:$(go env GOPATH)/bin' >> ~/.profile && source ~/.profile
echo

echo "Installing Allorand..."
git clone https://github.com/allora-network/allora-chain.git
cd allora-chain && make all
echo

echo "Checking allorand version..."
allorad version
echo

echo "Importing wallet..."
allorad keys add testkey --recover
echo

echo "Installing worker node..."
git clone https://github.com/allora-network/basic-coin-prediction-node

