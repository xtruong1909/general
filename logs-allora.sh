#!/bin/bash

# Định nghĩa mã màu ANSI
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

cleanup() {
    echo "Received Ctrl+C. Exiting gracefully..."
    exit 0
}

trap cleanup SIGINT

# Hiển thị "Nubit Node" màu vàng
echo -e "${YELLOW}Nubit Node${NC}"
journalctl -u nubit -n 6 -o cat --no-pager

# Gửi request bằng curl và lưu output vào biến
output1=$(
curl -s --location 'http://localhost:6000/api/v1/functions/execute' \
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

echo
echo -e "${GREEN}Allora Worker-1:${NC}"
echo "$output1"
echo

output2=$(
curl -s --location 'http://localhost:6000/api/v1/functions/execute' \
--header 'Content-Type: application/json' \
--data '{
    "function_id": "bafybeigpiwl3o73zvvl6dxdqu7zqcub5mhg65jiky2xqb4rdhfmikswzqm",
    "method": "allora-inference-function.wasm",
    "parameters": null,
    "topic": "2",
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

echo
echo -e "${GREEN}Allora Worker-1:${NC}"
echo "$output2"
echo

output7=$(
curl -s --location 'http://localhost:6000/api/v1/functions/execute' \
--header 'Content-Type: application/json' \
--data '{
    "function_id": "bafybeigpiwl3o73zvvl6dxdqu7zqcub5mhg65jiky2xqb4rdhfmikswzqm",
    "method": "allora-inference-function.wasm",
    "parameters": null,
    "topic": "7",
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

echo
echo -e "${GREEN}Allora Worker-1:${NC}"
echo "$output7"
echo

exit 0
