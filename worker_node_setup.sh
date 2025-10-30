#!/bin/bash

sudo hostnamectl set-hostname k8s-worker1.node.internal

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
# echo "Joining the Kubernetes cluster"
# sudo kubeadm join <master-node-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
# if [ $? -eq 0 ]; then
#     echo "Worker node joined the cluster successfully"
# else
#     echo "Failed to join the worker node to the cluster"
#     exit 1
# fi
echo "Kubernetes worker node setup completed successfully"