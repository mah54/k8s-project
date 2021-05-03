# k8s-project
Prepare 6 resources with at least 2G RAM and 2 CPUs. We will use 3 of them for control plane nodes and the others for worker nodes.
The hosts file contains the IP of resources. Here I have mapped the IPs to names at /etc/hosts and written the names instead of IPs. You can change them to match your hosts.

## Install Required Packages All Nodes

Clone this repository and then on your localhost, run the playbook to install required packages on all servers:

```bash
ansible-playbook -i hosts package-installation-playbook.yaml
```
There's also bashscripts with the same name of these playbooks in bashscript folder. They can be used on individual hosts with the same order as above.

## Setup Control Plane nodes

Then choose one control plane node to initialize the cluster. Other nodes (control planes and workers) will joins this one. In this script the variable LB_IP is the load balancer IP address. On the chosen node run the command bellow:
```bash
sudo chmod +x createControlPlaneNode.sh
```
In the output, look for join commands. There should be two of them. One for joining control plane nodes and one for worker node. Use them on nodes to complete your cluster.
