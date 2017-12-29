# optional: install dashboard:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
##kubectl create rolebinding web-admin-binding --clusterrole=admin --user=system:bootstrap:(*part of token before the dot at kubecreate*) --namespace=default

# setup consul
cd ../consul-on-kubernetes
## go to consul directory and run the ./populate script
./cleanup && ./populate
kubectl logs -f consul-0

# create CM for NGIC
cd ../ngic-k8s
kubectl create configmap ngic-config --from-file=config

cd ../k8s-testing-scripts

#create custom resource defined network:
kubectl create -f ngic/crd-network.yaml

#create a few sample networks
kubectl create -f ngic/ngic-networks.yaml

#launch multihomed pod
kubectl create -f ngic/ngic-pods.yaml

kubectl get pods


### Notes:

# For future runs, rather than delete and repopulate consul, do:
## kubectl exec -it ngic-traffic -- ./delete.sh

# Example on kubeadm dashboard RBAC:
## kubectl create rolebinding web-admin-binding --clusterrole=admin -- user=system:bootstrap:a358ed --namespace=default
