#!/bin/bash

mkdir -p elixir && > elixir/validator.env

IP=$(curl -s ifconfig.me)
echo -e "$(printf '\033[1;92m')Dia chi IP: $IP$(printf '\033[0m')" 

read -p "$(printf '\033[1;92m')Nhap ten node: $(printf '\033[0m')" ELIXIR_NODE_NAME
read -p "$(printf '\033[1;92m')Nhap dia chi vi nhan airdrop: $(printf '\033[0m')" ADDR_WALLET
read -p "$(printf '\033[1;92m')Nhap private key: $(printf '\033[0m')" PRIV_KEY

echo "Da luu thong tin vao /elixir/validator.env file..."

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
    docker stop elixir
    docker rm elixir
fi

docker run -d --env-file elixir/validator.env --name elixir --restart unless-stopped elixirprotocol/validator:v3
