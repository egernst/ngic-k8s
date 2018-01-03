# setup consul
cd ../consul-on-kubernetes
## go to consul directory and run the ./populate script
./cleanup && ./populate
kubectl logs -f consul-0

# create CM for NGIC
cd ../ngic-k8s
kubectl create configmap ngic-config --from-file=config

# create secret for mounting the launch script (as executable)
kubectl create secret generic ngic-scripts --from-file=scripts

# create custom resource defined network:
kubectl create -f k8s/crd-network.yaml

# create a few sample networks
kubectl create -f k8s/ngic-networks.yaml

# setup SR-IOV. these 2 interfaces are the same as used in k8s/ngic-networks.yaml
./infra/sriov.sh ens785f0 0
./infra/sriov.sh ens785f1 1

# create the service
kubectl create -f k8s/ngic-services.yaml

# launch multihomed pod
kubectl apply -f k8s/ngic-deployment.yaml --record

kubectl get pods


### Notes:

# For future runs, rather than delete and repopulate consul, do:
## kubectl exec -it ngic-traffic-deployment-(sometag) -- ./delete.sh

# Example on kubeadm dashboard RBAC:
## kubectl create rolebinding web-admin-binding --clusterrole=admin -- user=system:bootstrap:a358ed --namespace=default
