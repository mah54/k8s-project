#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/baremetal/deploy.yaml
sleep 3
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{ .spec.ports[?(@.name=="http")].nodePort }')

KUBE_EDITOR='sed -i "s/ClusterIP/NodePort/"' kubectl edit service prometheus-kube-prometheus-prometheus -n monitoring
sleep 3
PROM_PORT=$(kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus -o jsonpath='{ .spec.ports[?(@.name=="http")].nodePort }')

Kubectl apply -f monitoring-ingress.yaml

sed -i "s/INGRESS_PORT/$INGRESS_PORT/g" ~/k8s-project/monitoring/haproxy-appendix.cfg
sed -i "s/PROM_PORT/$PROM_PORT/g" ~/k8s-project/monitoring/haproxy-appendix.cfg
sudo cat haproxy-appendix.cfg >> /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
