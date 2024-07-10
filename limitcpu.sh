#!/bin/bash

apt install cgroup-tools
sudo cgcreate -g cpu:cpulimit_group
sudo mkdir -p /sys/fs/cgroup/cpu
sudo bash -c 'echo "80000" > /sys/fs/cgroup/cpu/cpu.max'
sudo cgexec -g cpu:cpulimit_group systemctl restart nubit


# Names of Docker containers to limit CPU
containers=("inference-basic-eth-pred" "updater-basic-eth-pred" "worker-basic-eth-pred" "head-basic-eth-pred")

# Set CPU limit for each container
for container in "${containers[@]}"
do
    # Get the PID of the container
    container_pid=$(docker inspect -f '{{.State.Pid}}' "$container")

    # Set up cgroup for the container
    sudo mkdir -p /sys/fs/cgroup/cpu/$container_pid
    echo $container_pid > /sys/fs/cgroup/cpu/$container_pid/tasks

    # Set CPU limit for the cgroup
    echo 80000 > /sys/fs/cgroup/cpu/cpu.cfs_quota_us
    echo 100000 > /sys/fs/cgroup/cpu/cpu.cfs_period_us

    echo "Container $container CPU limited."
done
