#!/bin/bash

cd allora-chain/

echo "$Pass" | allorad keys list

# Check address
if [ -z "$address" ]; then
  read -p "Paste address here: " address
fi

for ((i=1; i<=50; i++)); do
  echo "faucet n $i..."
  curl -sS "https://faucet.edgenet.allora.network/send/edgenet/$address"
  sleep 5
done

echo "Finish"
