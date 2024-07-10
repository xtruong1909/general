#!/bin/bash

cd allora-chain/

allorad keys list
echo

read -p "Paste address here: " address

echo "Wallet Address"
echo $address


for ((i=1; i<=50; i++)); do
  echo "faucet n $i..."
  curl -sS "https://faucet.edgenet.allora.network/send/edgenet/$address"
  sleep 5
done

echo "Finish"
