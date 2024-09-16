#!/bin/bash

cpu_threshold=95  # CPU usage threshold (%)
ram_threshold=95  # RAM usage threshold (%)
check_count=5     # Number of checks

# Function to check CPU usage
check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    echo $cpu_usage
}

# Function to check RAM usage
check_ram_usage() {
    local ram_usage=$(free | awk '/Mem/{printf("%d"), $3/$2*100}')
    echo $ram_usage
}

# Main check loop
cpu_check_counter=0
ram_check_counter=0

for ((i=0; i<check_count; i++)); do
    cpu_usage=$(check_cpu_usage)
    ram_usage=$(check_ram_usage)

    echo "Check $((i+1)): CPU usage = $cpu_usage%, RAM usage = $ram_usage%"

    if (( $(echo "$cpu_usage >= $cpu_threshold" | bc -l) )); then
        echo "Check $((i+1)): CPU usage is above the threshold."
        ((cpu_check_counter++))
    fi

    if (( $(echo "$ram_usage >= $ram_threshold" | bc -l) )); then
        echo "Check $((i+1)): RAM usage is above the threshold."
        ((ram_check_counter++))
    fi

    sleep 90  # Sleep for 15s between checks
done

# Reboot if threshold exceeded for all checks
if [ $cpu_check_counter -eq $check_count ] || [ $ram_check_counter -eq $check_count ]; then
    echo "Rebooting..."
    reboot
else
    echo "No reboot."
fi
