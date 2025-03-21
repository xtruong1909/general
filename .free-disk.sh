#!/bin/bash

sudo fstrim -av

sudo dd if=/dev/zero of=empty_file bs=1M status=progress

sleep 15

rm -rf empty_file
