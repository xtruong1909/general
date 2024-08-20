#!/bin/bash

# Đặt biến cho lỗi cần kiểm tra
ERROR_MESSAGE="error from daemon in stream: Error grabbing logs: invalid character '\\x00' looking for beginning of value"

# Các container và lệnh docker-compose
CONTAINERS=("worker10m" "worker20m" "worker24h")
COMPOSE_DIR="/root/basic-coin-prediction-node"

# Khởi tạo biến RESTART_REQUIRED
RESTART_REQUIRED=false

# Kiểm tra các log của các container
for CONTAINER in "${CONTAINERS[@]}"; do
    echo "Checking logs for $CONTAINER..."
    
    # Kiểm tra log gần nhất
    if docker logs "$CONTAINER" 2>&1 | grep -q "$ERROR_MESSAGE"; then
        echo "Error detected in $CONTAINER logs."
        RESTART_REQUIRED=true
        break
    fi
done

# Nếu phát hiện lỗi, thực hiện khởi động lại
if [ "$RESTART_REQUIRED" = true ]; then
    echo "Restarting Docker containers..."
    cd "$COMPOSE_DIR" || exit
    docker-compose down
    docker-compose up -d
else
    echo "No errors detected in any of the logs."
fi
