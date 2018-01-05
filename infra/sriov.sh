#!/bin/bash
#
#Usage: ./sriov.sh ens785f0

echo 0 | sudo tee /sys/class/net/$1/device/sriov_numvfs
echo 8 | sudo tee /sys/class/net/$1/device/sriov_numvfs
sudo ip link set $1 up
for i in {0..7}; do sudo ip link set $1 vf $i spoofchk off; done
for i in {0..7}; do sudo ip link set dev $1 vf $i state enable; done

