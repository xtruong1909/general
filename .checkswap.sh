#!/bin/bash

# Check swap used > 2GB
USED_SWAP=$(free | grep Swap | awk '{print $3}')
if [ "$USED_SWAP" -gt 2097152 ]; then
  echo "Swap usage is greater than 2GB. Proceeding with service restart..."
  
  # Stop dill and hemi
  systemctl stop dill
  systemctl stop hemi
  
  # Wait 60s
  sleep 60
  
  # Restart dill and hemi
  systemctl restart dill
  systemctl restart hemi
  
  echo "Services dill and hemi have been restarted."
else
  echo "Swap usage is below 2GB. No action taken."
fi
