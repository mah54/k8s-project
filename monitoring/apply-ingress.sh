#!/bin/bash

#You're supposed to have installed ingress already. If not, run below commands and get ingress-controller-port
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/baremetal/deploy.yaml
#kubectl get svc ingress-nginx-controller -n ingress-nginx
#Then replace port number here:

INGRESS_PORT=32113

Kubectl apply -f monitoring-ingress.yaml

sed -i "s/INGRESS_PORT/$INGRESS_PORT/g" ~/k8s-project/monitoring/haproxy-appendix.cfg
sudo cat haproxy-appendix.cfg >> /etc/haproxy/haproxy.cfg
