#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi

#--- Creating a Cluster
#Create our kubernetes cluster, specify a pod network range matching that in calico.yaml
#Only on the Control Plane Node, download the yaml files for the pod network
wget -c https://docs.projectcalico.org/manifests/calico.yaml

#Set apiVersion to latest
sed -i 's/policy\/v1beta1/policy\/v1/' calico.yaml

##Look inside calico.yaml and find the setting for Pod Network IP address range CALICO_IPV4POOL_CIDR, 
##adjust if needed for your infrastructure to ensure that the Pod network IP
##range doesn't overlap with other networks in our infrastructure.

#Generate a default kubeadm init configuration file...this defines the settings of the cluster being built.
kubeadm config print init-defaults | tee ClusterConfiguration.yaml

#Inside default configuration file, we need to change four things.
#1. The IP Endpoint for the API Server localAPIEndpoint.advertiseAddress:
#2. nodeRegistration.criSocket from docker to containerd
#3. Set the cgroup driver for the kubelet to systemd, it's not set in this file yet, the default is cgroupfs
#4. Edit kubernetesVersion to match the version you installed in 0-PackageInstallation-containerd.sh

#Change the address of the localAPIEndpoint.advertiseAddress to the Control Plane Node's IP address
sed -i "s/  advertiseAddress: 1.2.3.4/  advertiseAddress: $(hostname  -I | cut -f1 -d' ')/" ClusterConfiguration.yaml

#Set the CRI Socket to point to containerd
sed -i 's/  criSocket: \/var\/run\/dockershim\.sock/  criSocket: \/run\/containerd\/containerd\.sock/' ClusterConfiguration.yaml

#Set the cgroupDriver to systemd...matching that of your container runtime, containerd
cat <<EOF >> ClusterConfiguration.yaml
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

#Add CRI socket since because there's still a check for docker in the kubeadm init process, 
sudo kubeadm init \
    --config=ClusterConfiguration.yaml \
    --cri-socket /run/containerd/containerd.sock \
    --node-name=$HOSTNAME

#Configure our account on the Control Plane Node to have admin access to the API server from a non-privileged account.
USER=ubuntu
USER_HOME="/home/ubuntu"
mkdir -p $UBUNTU_HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $UBUNTU_HOME/.kube/config
sudo chown $USER:$USER $UBUNTU_HOME/.kube/config

#Deploy yaml file for your pod network.
kubectl apply -f calico.yaml
