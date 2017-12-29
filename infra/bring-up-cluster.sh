sudo kubeadm reset
sudo modprobe br_netfilter
sudo kubeadm init --config kubeadm.yaml
# Copy and paste the token from kubeadm join --token [something.something]

rm -rf ~/.kube/
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
## At this point, kubectl get nodes will still say NotReady
kubectl apply -f https://docs.projectcalico.org/v2.1/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
kubectl get nodes -w


sed -i "$(grep -n k8s_auth ngic/01-multus-cni.conf | awk {'print $1'} | tr -d :)s/.*/$(sudo grep k8s_auth_token /etc/cni/net.d/10-calico.conf)/" ngic/01-multus-cni.conf

sudo cp ngic/01-multus-cni.conf /etc/cni/net.d/
sudo systemctl restart kubelet
#sudo systemctl status kubelet

#sudo vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
##Environment="KUBELET_FEATURE_GATE_ARGS=--feature-gates=HugePages=true,CPUManager=true --cpu-manager-policy=static --cpu-manager-reconcile-period=5s --kube-reserved=cpu=500m"
##ExecStart=/usr/bin/kubelet $KUBELET_FEATURE_GATE_ARGS ...

#sudo systemctl daemon-reload;sudo systemctl restart kubelet

master=$(hostname)
kubectl taint nodes "$master" node-role.kubernetes.io/master:NoSchedule-

sudo rmmod br_netfilter


###  Notes:

# See this link for additional args for (very picky) kubeadm file: https://github.com/kubernetes/kubernetes/blob/master/cmd/kubeadm/app/cmd/upgrade/common_test.go#L26

# Alternatively, without kubeadm config, init like:
####sudo kubeadm init --pod-network-cidr 10.244.0.0/16
