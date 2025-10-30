# kube-cluster-setup

This is a kubernetes cluster setup with 1 master node and 2 worker nodes.
Use the scripts to setup kubernetes cluster

## Steps

### 1. Creating EC2 instances

Creating Security Group

```
aws ec2 create-security-group --group-name testSecurityGroup --description "Security Group for Kubernetes Setup"  \
  --vpc-id <vpc-id> --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=kube-setup-SG}]"
```
Add SSH and 30080 port to security group
```
aws ec2 authorize-security-group-ingress \
    --group-id <security-group-id>\
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
```
```
aws ec2 authorize-security-group-ingress \
    --group-id <security-group-id>\
    --protocol tcp \
    --port 30080 \
    --cidr 0.0.0.0/0
```

 Master VM
```
aws ec2 run-instances --image-id 'ami-02d26659fd82cf299' \
	--instance-type 't2.medium' \
	--key-name '<key-name>' \
	--block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-007c54c0145b150cd","VolumeSize":8,"VolumeType":"gp3","Throughput":125}}' \
	--network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["<security-group-id>"]}' \
	--credit-specification '{"CpuCredits":"standard"}' \
	--tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"master"}]}' \
	--metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' \
	--private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
	--count '1' 
```

Worker VM <br>

```
aws ec2 run-instances --image-id 'ami-02d26659fd82cf299' \
	--instance-type 't2.medium' \
	--key-name '<key-name>' \
	--block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-007c54c0145b150cd","VolumeSize":8,"VolumeType":"gp3","Throughput":125}}' \
	--network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["<security-group-id>"]}' \
	--credit-specification '{"CpuCredits":"standard"}' \
	--tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"worker-1"}]}' \
	--metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' \
	--private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
	--count '1' 
```

```
aws ec2 run-instances --image-id 'ami-02d26659fd82cf299' \
	--instance-type 't2.medium' \
	--key-name '<key-name>' \
	--block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-007c54c0145b150cd","VolumeSize":8,"VolumeType":"gp3","Throughput":125}}' \
	--network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["<security-group-id>"]}' \
	--credit-specification '{"CpuCredits":"standard"}' \
	--tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"worker-2"}]}' \
	--metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' \
	--private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
	--count '1' 
```

### 2. Set hostnames for Master and worker nodes

enter the below commands in master and worker nodes to set hostnames
```
sudo hostnamectl set-hostname k8s-master.node.internal
```

```
sudo hostnamectl set-hostname k8s-worker1.node.internal
```
```
sudo hostnamectl set-hostname k8s-worker2.node.internal
```

### 3. Install Kubernetes components and Setup Control plane on master node
use the script `master_node_setup.sh`
```
chmod +x master_node_setup.sh
./master_node_setup.sh
```
look for the control plane initialization logs in terminal and take a copy of `kubeadmin join` command. Logs will be something like this:
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join <ip>:6443 --token ############ \
	--discovery-token-ca-cert-hash sha256:######################################
kubernetes cluster initialized successfully
```

### 4. Install Kubernetes components and join the worker nodes to control plane
use the script `worker_node_setup.sh` for kubernetes component installation
```
chmod +x master_node_setup.sh
./worker_node_setup.sh
```
Once this is successfull, use the `kubeadmin join` command from Master node to connect it to control plane

### 5.Check nodes in master node
```
kubectl get nodes -o wide

```