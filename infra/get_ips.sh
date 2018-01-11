#!/bin/bash
kubectl get pods  | grep cp |  kubectl exec $(awk '{print $1}') -- ifconfig | grep 192 | awk '{print "s11: " $2}'
ps -ef | grep ngic | grep dataplane | awk '{print $19 ":" $20 " " $23 ":" $24 " " $27 ":" $28}'  #no afpacket TODO
ps -ef | grep ngic | grep dataplane | awk '{print $20 ":" $21 " " $24 ":" $25 " " $28 ":" $29}'  #afpacket TODO
