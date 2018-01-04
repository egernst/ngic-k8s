# Note that intel_iommu and hugepages settings:
#$ cat /proc/cmdline
#BOOT_IMAGE=/vmlinuz-4.10.0-42-generic root=/dev/mapper/s2rf6n6--vg-root ro intel_iommu=on hugepagesz=1G hugepages=16
# Note: (To change the above, edit  /etc/default/grub then run `update-grub`
# 
# ----
# Also change the huge pages in fstab.  (Do a mkdir -p /dev/hugepages )
#
#stack@s2rf6n6:~$ cat /etc/fstab
## ....
#nodev /dev/hugepages hugetlbfs pagesize=1GB 0 0
#

sudo modprobe vfio-pci
sudo mkdir -p /sriov-cni


#sudo modprobe br_netfilter # this was only needed for using bridges
sudo kubeadm reset
sudo kubeadm init --config infra/kubeadm.yaml
# Copy and paste the token from kubeadm join --token [something.something]

rm -rf ~/.kube/
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

## At this point, kubectl get nodes will still say NotReady
kubectl apply -f https://docs.projectcalico.org/v2.1/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
kubectl get nodes -w


sed -i "$(grep -n k8s_auth infra/01-multus-cni.conf | awk {'print $1'} | tr -d :)s/.*/$(sudo grep k8s_auth_token /etc/cni/net.d/10-calico.conf)/" infra/01-multus-cni.conf

sudo cp infra/01-multus-cni.conf /etc/cni/net.d/
sudo systemctl restart kubelet
#sudo systemctl status kubelet

#sudo vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
##Environment="KUBELET_FEATURE_GATE_ARGS=--feature-gates=HugePages=true,CPUManager=true --cpu-manager-policy=static --cpu-manager-reconcile-period=5s --kube-reserved=cpu=500m"
##ExecStart=/usr/bin/kubelet $KUBELET_FEATURE_GATE_ARGS ...

#sudo systemctl daemon-reload;sudo systemctl restart kubelet

master=$(hostname)
kubectl taint nodes "$master" node-role.kubernetes.io/master:NoSchedule-

## sudo rmmod br_netfilter # this was only needed for using bridges


###  Notes:

# See this link for additional args for (very picky) kubeadm file: https://github.com/kubernetes/kubernetes/blob/master/cmd/kubeadm/app/cmd/upgrade/common_test.go#L26

# Alternatively, without kubeadm config, init like:
####sudo kubeadm init --pod-network-cidr 10.244.0.0/16


# optional: install dashboard:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
##kubectl create rolebinding web-admin-binding --clusterrole=admin --user=system:bootstrap:(*part of token before the dot at kubecreate*) --namespace=default

