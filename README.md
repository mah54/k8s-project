# k8s-project

Prepare 6 resources with at least 2G RAM and 2 CPUs. We will use 3 of them for control plane nodes and the others for worker nodes.
The hosts file contains the IP of resources. Here I have mapped the IPs to names at /etc/hosts and written the names instead of IPs. You can change them to match your hosts.

## Setup HA Cluster

Clone this repository and change to folder ha-cluster

### Install Required Packages All Nodes

Run package-installation-playbook.yaml to install required packages on all servers:

```bash
ansible-playbook -i hosts package-installation-playbook.yaml
```
There's also bashscripts with the same name of these playbooks in bashscript folder. They can be used on individual hosts with the same order as above.

### Setup Cluster Nodes

Then choose one control plane node to initialize the cluster. Other nodes (control planes and workers) will joins this one. In this script the variable LB_IP is the load balancer IP address. On the chosen node run the command bellow:
```bash
sudo chmod +x createControlPlaneNode.sh
sudo ./createControlPlaneNode.sh
```
In the output, look for join commands. There should be two of them. One for joining control plane nodes and one for worker node. Copy the one fir control plane to joinCPtoCluster.yaml file and the other to joinWtoCluster.yaml file. Then run them together:
```bash
ansible-playbook -i hosts joinCPtoCluster.yaml joinWtoCluster.yaml
```

## Monitoring

To install helm and kube-prometheus-stack chart, run install-kube-prometheus-stack.sh bashscript on one of the control plane nodes:
```bash
./install-kube-prometheus-stack.sh
```
Then you should change bind address for two manifests in control plane nodes:
```bash
ansible-playbook -i hosts fix-bind-address-playbook.yaml
```
Finally make sure you have access to kubernetes on load balancer node, and run the apply-ingress.sh.
```bash
sudo chmod +x apply-ingress.sh
./apply-ingress.sh
```
You can access grafana on your load balancer, using these credentials:
- username: admin
- password: prom-operator

## Logging

To deploy elasticsearch, apply related yaml files in numerical order. You may need to add an extra node to the cluster. Then deploy kibana and filebeat. You need to change the ip addresses before deploying.
```bash
kubectl apply -f elasticsearch/01-namespace-logging.yaml
kubectl apply -f elasticsearch/02-elasticsearch-pv.yaml
kubectl apply -f elasticsearch/03-elasticsearch-pvc.yaml
kubectl apply -f elasticsearch/04-elasticsearch.yaml
kubectl apply -f kibana.yaml
kubectl apply -f filebeat.yaml
```

