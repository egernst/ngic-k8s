```
├── crd-network.yaml			# create network resource
├── ngic-deployment-dpdk.yaml		# mounts /sriov-cni & /dev/vfio for both DP and Traffic
├── ngic-deployment-hybrid.yaml		# mount for DP only 
├── ngic-deployment.yaml		# no mount
├── ngic-networks-bridge.yaml		# all have bridge networks only
├── ngic-networks-dpdk.yaml		# DP/Traffic both have vfio-pci
├── ngic-networks-hybrid.yaml		# DP has vfio-pci, Traffic has AF_PACKET
├── ngic-networks.yaml			# DP/Traffic have AF_PACKET
├── ngic-pods.yaml 			# deprecated, Kind: Pod only
└── ngic-services.yaml			# necessary for DNS
```
