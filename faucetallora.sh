#!/bin/bash

cd allora-chain/

echo "$Pass" | allorad keys list

read -p "paste address here: " address

for ((i=1; i<=20; i++)); do
  echo "faucet n $i..."
  curl -sS https://faucet.edgenet.allora.network/send/edgenet/$address
  sleep 5
done

echo "Finish"
