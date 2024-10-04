#!/bin/bash

# Lấy dung lượng swap đã sử dụng (chỉ lấy phần đã sử dụng và loại bỏ đơn vị)
USED_SWAP=$(free | grep Swap | awk '{print $3}')

# Kiểm tra nếu swap sử dụng lớn hơn 2GB (2*1024*1024 KB)
if [ "$USED_SWAP" -gt 2097152 ]; then
  echo "Swap usage is greater than 2GB. Proceeding with service restart..."
  
  # Dừng dịch vụ dill và hemi
  systemctl stop dill
  systemctl stop hemi
  
  # Đợi 60 giây
  sleep 60
  
  # Khởi động lại dịch vụ dill và hemi
  systemctl restart dill
  systemctl restart hemi
  
  echo "Services dill and hemi have been restarted."
else
  echo "Swap usage is below 2GB. No action taken."
fi
