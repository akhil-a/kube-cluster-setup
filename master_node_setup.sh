#!/bin/bash

echo "updating system packages"
sudo apt update && sudo apt upgrade -y
echo "adding required kernel modules and network settings for kubernetes"
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.asc
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
echo "installing containerd and kubernetes components"
sudo apt install -y containerd apt-transport-https ca-certificates curl kubelet kubeadm kubectl


echo "Load necessary kernel modules for Kubernetes"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
echo "kernel modules loaded successfully"
echo "Configure network settings for Kubernetes"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
echo "network settings applied successfully"

echo "configuring containerd runtime"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo systemctl enable --now kubelet

for component in containerd kubelet;do
    status=$(sudo systemctl is-active  $component)
    if [ $status == "active" ]; then
        echo "$component is running"
    else
        echo "$component failed to start"
        sudo systemctl status $component
        exit 1
    fi
done
echo "kubernetes components installed successfully"

if [ -f /etc/kubernetes/admin.conf ]; then
    echo "Kubernetes already initialized — skipping kubeadm init"
else
    echo "Initializing Kubernetes cluster"
    sudo kubeadm init --pod-network-cidr=192.20.0.0/16
    if [ $? -eq 0 ]; then
        echo "kubeadm init completed successfully"
    else
        echo "kubeadm init failed"
        exit 1
    fi
fi

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "kubeconfig file set up successfully"
kubectl apply -f kube-flannel.yaml
if [ $? -eq 0 ]; then
    echo "Flannel network plugin applied successfully"
else
    echo "Failed to apply Flannel network plugin"
    exit 1
fi
echo "sleeping for 1minute to allow kube-apiserver to start"
sleep 60

master_node_status=$(kubectl get node k8s-master.node.internal | awk 'NR==2 {print $2}')
if [ "$master_node_status" == "Ready" ]; then
    echo "Master node is Ready"
else
    echo "Master node is not Ready yet. Current status: $master_node_status"
    kube
    exit 1
fi
kubectl get nodes -o wide   
echo "Kubernetes master node setup completed successfully"