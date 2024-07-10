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


# Build and start Docker containers with CPU limits
echo "Building Docker containers with CPU limits..."
sudo cgexec -g cpu:cpulimit_group systemctl restart docker.service
echo

# Rebuild Allora Worker Node
echo "Rebuild Allora Worker Node"
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
