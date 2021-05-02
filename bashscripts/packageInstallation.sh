#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi

#---Preparing nodes---
#Disable swap
swapoff -a

#containerd prerequisites, first load two modules and configure them to load on boot
modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

#Setup required sysctl params
cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

##Apply sysctl params
sysctl --system

#Install containerd
apt-get update 
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y containerd.io

#Create a containerd configuration file
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml


#Set the cgroup driver for containerd to systemd which is required for the kubelet.
sed -i 's/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]\n            SystemdCgroup = true/' /etc/containerd/config.toml

#Restart containerd with the new configuration
systemctl restart containerd

#Install Kubernetes packages - kubeadm, kubelet and kubectl
##Add Google's apt repository gpg key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

##Add the Kubernetes apt repository
bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

apt-get update


#Install the required packages
VERSION=1.21.0-00
apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
apt-mark hold kubelet kubeadm kubectl containerd.io

#Ensure kublet and containerd services are enabled
systemctl enable kubelet.service
systemctl enable containerd.service
