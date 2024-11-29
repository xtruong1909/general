#!/bin/bash

# Check swap used > 2.5GB
USED_SWAP=$(free | grep Swap | awk '{print $3}')
if [ "$USED_SWAP" -gt 2621440 ]; then
  echo "Swap usage is greater than 2.5GB. Proceeding with service restart..."
  
  # Stop dill and hemi
  systemctl stop dill
  
  # Wait 10s
  sleep 10
  
  # Restart dill and hemi
  systemctl restart dill
  
  echo "Services dill and hemi have been restarted."
else
  echo "Swap usage is below 2.5GB. No action taken."
fi
