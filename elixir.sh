#!/bin/bash

mkdir -p elixir && > elixir/validator.env

cat <<EOF > elixir/validator.env
ENV=testnet-3

STRATEGY_EXECUTOR_IP_ADDRESS=$IP
STRATEGY_EXECUTOR_DISPLAY_NAME=$ELIXIR_NODE_NAME
STRATEGY_EXECUTOR_BENEFICIARY=$ADDR_WALLET
SIGNER_PRIVATE_KEY=$PRIV_KEY

EOF

if ! docker images | grep -q 'elixirprotocol/validator\s*v3'; then
    docker pull elixirprotocol/validator:v3
else
    echo "Image elixirprotocol/validator:v3 da ton tai tren he thong."
fi


if [ $(docker ps -a -q -f name=elixir) ]; then
    docker rm -f elixir
fi

docker run -d --env-file elixir/validator.env --name elixir --restart unless-stopped elixirprotocol/validator:v3
