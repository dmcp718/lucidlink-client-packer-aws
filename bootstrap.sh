#!/bin/bash

set -x

# Format data disk
sudo mkfs.xfs -f /dev/nvme1n1
sudo mkdir /data
sudo mount /dev/nvme1n1 /data
sudo chown -R lucidlink:lucidlink /data

echo "Enabling 'systemctl enable lucidlink-1.service'"
sudo systemctl enable lucidlink-1.service
wait
echo "Starting 'systemctl start lucidlink-1.service'"
sudo systemctl start lucidlink-1.service
wait
until lucid --instance 501 status | grep -qo "Linked"
do
    sleep 1
done
sleep 1
/usr/bin/lucid --instance 501 config --set --DataCache.Size 80G