#!/bin/bash

# Hàm xử lý khi nhận tín hiệu SIGINT (Ctrl + C)
cleanup() {
    echo "Received Ctrl+C. Exiting gracefully..."
    exit 0
}

# Bắt tín hiệu SIGINT (Ctrl + C) và gọi hàm cleanup
trap cleanup SIGINT

# Gửi request bằng curl và lưu output vào biến
echo "ALLORA WORKER NODE"
output=$(
curl --location 'http://localhost:6000/api/v1/functions/execute' \
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

# In kết quả từ request
echo "Output:"
echo "$output"
echo

# Xem logs từ journalctl và chỉ hiển thị 10 dòng
echo "NUBIT NODE"
journalctl -u nubit -n 10 -o cat --no-pager

# Thoát chương trình sau khi hiển thị logs và trả về trạng thái nhập lệnh
echo "Exiting script..."
exit 0
