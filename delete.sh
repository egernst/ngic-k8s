#!/bin/bash

declare -a todelete=(
 "CP_CPDP_IP"
 "DP_CPDP_IP"
 "MME_S11_IP"
 "RTR_SGI_IP"
 "SGW_S11_IP"
 "SGW_S1U_IP"
 "SGW_SGI_IP"
 "SGW_SGI_IP" )

for i in "${todelete[@]}"
do
    consul kv delete --http-addr=consul:8500 $i
done
