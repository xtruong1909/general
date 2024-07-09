#!/bin/bash

cleanup() {
    echo "Received Ctrl+C. Exiting gracefully..."
    exit 0
}

trap cleanup SIGINT

echo "Nubit Node"
journalctl -u nubit -n 6 -o cat --no-pager

output=$(
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
echo "Allora Worker Node:"
echo "$output"
echo

exit 0
