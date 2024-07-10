#!/bin/bash

cpu_limit=90

while true; do
  for pid in $(ps -e -o pid=); do
    # Kiem tra neu cpulimit da duoc ap dung cho tien trinh nay hay chua
    if ! ps -p $pid -o cmd= | grep -q "cpulimit"; then
      # Ap dung cpulimit cho tien trinh
      sudo cpulimit -l $cpu_limit -p $pid -b
    fi
  done
  sleep 5
done
