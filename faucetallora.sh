#!/bin/bash

cd allora-chain/

echo "$Pass" | allorad keys list

read -p "Paste address here: " address
echo $address


for ((i=1; i<=50; i++)); do
  echo "faucet n $i..."
  curl -sS "https://faucet.edgenet.allora.network/send/edgenet/$address"
  sleep 5
done

echo "Finish"
