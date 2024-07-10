#!/bin/bash

# Check if cgroup-tools is installed; if not, install it
if ! dpkg -s cgroup-tools &> /dev/null; then
    echo "Installing cgroup-tools..."
    sudo apt install -y cgroup-tools
fi

# Check if cpulimit_group already exists; if not, create it and set limits
if [ ! -d /sys/fs/cgroup/cpu/cpulimit_group ]; then
    echo "Creating CPU cgroup and setting limits..."
    sudo cgcreate -g cpu:cpulimit_group
    sudo mkdir -p /sys/fs/cgroup/cpu
    sudo bash -c 'echo "80000" > /sys/fs/cgroup/cpu/cpu.max'
else
    echo "CPU cgroup 'cpulimit_group' already exists. Skipping creation."
fi

# Restart nubit service with CPU limits
echo "Restarting nubit service with CPU limits..."
sudo cgexec -g cpu:cpulimit_group systemctl restart nubit

# Change directory to your Docker project
echo "Changing directory to allora-chain/basic-coin-prediction-node..."
cd allora-chain/basic-coin-prediction-node

# Build and start Docker containers with CPU limits
echo "Building Docker containers with CPU limits..."
sudo cgexec -g cpu:cpulimit_group docker-compose build
echo "Stopping existing Docker containers..."
sudo cgexec -g cpu:cpulimit_group docker-compose down
echo "Starting Docker containers in detached mode..."
sudo cgexec -g cpu:cpulimit_group docker-compose up -d
echo
