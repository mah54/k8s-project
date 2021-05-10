#!/bin/bash

#Install helm
wget https://get.helm.sh/helm-v3.5.4-linux-amd64.tar.gz
tar xzfv helm-v3.5.4-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

#Add repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update

#Create namespace for monitoring
kubectl create ns monitoring 

#Easy root access to cluster (for next command)
mkdir -p /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

#For etcd, the regular client listen address which is bound to the node IP does expose the /metrics endpoint, but requires authentication.
#To scrape metrics from etcd, create a secret with the certs and configuring the helm chart to mount and use them:
sudo kubectl -n monitoring create secret generic etcd-client-cert --from-file=/etc/kubernetes/pki/etcd/ca.crt --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key
echo """
kubeEtcd:
  serviceMonitor:
   scheme: https
   insecureSkipVerify: false
   serverName: localhost
   caFile: /etc/prometheus/secrets/etcd-client-cert/ca.crt
   certFile: /etc/prometheus/secrets/etcd-client-cert/healthcheck-client.crt
   keyFile: /etc/prometheus/secrets/etcd-client-cert/healthcheck-client.key
""" > values.yaml

#Install kube-prometheus-stack chart
helm install -f values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring 

#Fix kube-proxy
KUBE_EDITOR='sed -i "s/    metricsBindAddress: \"\"/    metricsBindAddress: \"0.0.0.0\"/"' kubectl edit cm/kube-proxy -n kube-system

# Fix kube-controller-manager
KUBE_EDITOR='sed -i "s/10252/10257/g"' kubectl edit service prometheus-kube-prometheus-kube-controller-manager -n kube-system
KUBE_EDITOR='sed -i "s/    port: http-metrics/    port: http-metrics\n    scheme: https\n    tlsConfig:\n      caFile: \/var\/run\/secrets\/kubernetes.io\/serviceaccount\/ca.crt\n      insecureSkipVerify: true/g"' kubectl edit servicemonitor prometheus-kube-prometheus-kube-controller-manager -n monitoring

# Fix kube-scheduler
KUBE_EDITOR='sed -i "s/10251/10259/g"' kubectl edit service prometheus-kube-prometheus-kube-scheduler -n kube-system
KUBE_EDITOR='sed -i "s/    port: http-metrics/    port: http-metrics\n    scheme: https\n    tlsConfig:\n      caFile: \/var\/run\/secrets\/kubernetes.io\/serviceaccount\/ca.crt\n      insecureSkipVerify: true/g"' kubectl edit servicemonitor prometheus-kube-prometheus-kube-scheduler -n monitoring

