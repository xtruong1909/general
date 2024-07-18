#!/bin/bash

cd allora-chain/

address=$(yes $pass | allorad keys list | grep address | awk '{print $3}')
echo $address


for ((i=1; i<=10; i++)); do
  echo "faucet n $i..."
  curl -sS "https://faucet.testnet-1.testnet.allora.network/send/allora-testnet-1/$address"
  sleep 10
done

echo "Finish"
