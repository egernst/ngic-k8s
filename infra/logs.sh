#!/bin/bash
if [ $# = 1 ]; then
    kubectl get pods  | grep $1 | kubectl logs -f $(awk '{print $1}')
else
    echo "Usage: ./logs.sh [ cp | dp | traffic ]" >&2
fi
