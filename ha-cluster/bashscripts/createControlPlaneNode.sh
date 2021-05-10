#!/bin/bash

#if [ $EUID -ne 0 ]; then
#    echo "$0 is not running as root. Try using sudo."
#    exit 2
#fi

#Load balancer IP
LB_IP=130.185.121.10

#--- Creating a Cluster
#Add all node addresses to /etc/host.
echo '''
### Cluster nodes ###
185.235.42.119 c1-cp1
185.235.42.182 c1-cp2
185.235.42.157 c1-cp3
185.235.42.151 c1-node1
185.235.42.146 c1-node2
185.235.42.189 c1-node3
130.185.121.10 load-balancer
#####################
''' | sudo tee -a /etc/hosts

#Create our kubernetes cluster, specify a pod network range matching that in calico.yaml
#Only on the Control Plane Node, download the yaml files for the pod network
wget -c https://docs.projectcalico.org/manifests/calico.yaml

#Set apiVersion to latest
sed -i 's/policy\/v1beta1/policy\/v1/' calico.yaml

##Look inside calico.yaml and find the setting for Pod Network IP address range CALICO_IPV4POOL_CIDR, 
##adjust if needed for your infrastructure to ensure that the Pod network IP
##range doesn't overlap with other networks in our infrastructure.

#Add CRI socket since because there's still a check for docker in the kubeadm init process, 
sudo kubeadm init \
    --control-plane-endpoint=$LB_IP:6443 \
    --upload-certs \
    --apiserver-advertise-address=$(hostname  -I | cut -f1 -d' ') \
    --pod-network-cidr=192.168.0.0/16 \
    --node-name=$HOSTNAME

#Configure our account on the Control Plane Node to have admin access to the API server from a non-privileged account.
KUSER=ubuntu
USER_HOME="/home/ubuntu"
mkdir -p $USER_HOME/.kube
sudo cp /etc/kubernetes/admin.conf $USER_HOME/.kube/config
sudo chown $KUSER:$KUSER $USER_HOME/.kube/config

#Access cluster with root user
#export KUBECONFIG=/etc/kubernetes/admin.conf

#Deploy yaml file for your pod network.
kubectl apply -f calico.yaml
