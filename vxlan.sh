#!/bin/bash

#sudo bash
apt-get -qq update > /dev/null
apt-get -qq install -y jq > /dev/null
set -x
ip link add vxlan0 type vxlan id 42 dev ens4 dstport 0
export CURRENT_IP=$(ip --json a show dev ens4 | jq '.[0].addr_info[0].local' -r)
echo "VM IP address is: $CURRENT_IP"
bridge fdb append to 00:00:00:00:00:00 dst $CURRENT_IP dev vxlan0

ip addr add 10.200.0.2/24 dev vxlan0 # Remember the IP 10.200.0.2, this is VXLAN ip of this machine
ip link set up dev vxlan0
systemctl stop apparmor.service
systemctl disable apparmor.service
```
Verify you got new VXLAN setup on this machine.
```
sudo apt install net-tools
ifconfig # search for VXLAN IP 
ping 10.200.0.2
