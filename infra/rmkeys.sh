kubectl get pods  | grep traffic |  kubectl exec $(awk '{print $1}') -- ./delete.sh
