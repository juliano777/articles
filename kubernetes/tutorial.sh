# =========================
# ======= ALL NODES =======
# =========================

# Install packages:

sudo dnf install -y \
  dnf-utils device-mapper-persistent-data lvm2 ebtables ethtool bash-completion



# First of all we need Docker:

wget -O - https://get.docker.com | sudo bash



# If the previous attempt fails...:

sudo dnf install --nobest -y docker-ce



# Add your user to Docker group:

sudo usermod -aG docker `whoami`



# Configuration directory of Docker:

sudo mkdir /etc/docker



# Setup Docker daemon:

sudo bash -c '
cat << EOF > /etc/docker/daemon.json
{
  "experimental": false,
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
// "experimental" -> Enable if you want to test experimental features
EOF
'



# Enable and start Docker service:

sudo systemctl enable --now docker.service



# File containing all modules necessary for k8s:

sudo bash -c '
cat << EOF > /etc/modules-load.d/k8s.conf
br_netfilter
ip_vs_rr
ip_vs_sh
ip_vs
ip_vs_wrr
nf_conntrack-ipv4
EOF
'



# Load all modules:

sudo systemctl restart systemd-modules-load.service



# Kubernetes repository file:

sudo bash -c '
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg \
https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
'



# Update repository list;

sudo dnf repolist -y



# Disable swap

# On /etc/fstab:

sudo sed 's/\(.*swap\)/#\1/g' -i /etc/fstab

# Immediate, via command:

sudo swapoff -a



# Disable and stop firewall:

sudo systemctl disable --now firewalld



# Disable Selinux:

sudo sed 's/SELINUX=.*/SELINUX=disabled/g' -i /etc/selinux/config && \
sudo setenforce 0



# Sysctl properties:

sudo bash -c '
cat << EOF > /etc/sysctl.d/k8s.conf && sysctl --system
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
'



# Packages of Kubernetes to install:

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes



# Clean up downloaded packages:

sudo dnf clean all



# Enable kubectl and kubeadm auto completion
# (needs bash-completion pre installed):

echo 'source <(kubectl completion bash)' | sudo tee /etc/profile.d/kubectl.sh

echo 'source <(kubeadm completion bash)' | sudo tee /etc/profile.d/kubeadm.sh

sudo chmod +x /etc/profile.d/kube{adm,ctl}.sh

source /etc/profile.d/kube{adm,ctl}.sh



# Create aditional directory for service kubelet:

sudo mkdir -p /etc/systemd/system/kubelet.service.d



# Create aditional file for service kubelet:

sudo bash -c '
cat << EOF > /etc/systemd/system/kubelet.service.d/11-cgroups.conf
[Service]

CPUAccounting=true
MemoryAccounting=true
EOF
'



# Reload systemd manager configuration

sudo systemctl daemon-reload



#

sudo bash -c '
cat << EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS='--cgroup-driver=systemd'
EOF
'



# Enable and start kubelet:

sudo systemctl enable kubelet



# ============================================================================



# ===========================
# ======= MASTER NODE =======
# ===========================



# Type your service network CIDR (X.X.X.X/X, Default: "10.96.0.0/12") :

read -p \
'Type your service network CIDR (X.X.X.X/X, Default: "10.96.0.0/12"):' \
SERVICE_CIDR



# if the answer was null...:
export SERVICE_CIDR="${SERVICE_CIDR:-10.96.0.0/12}"



# Type your network POD network CIDR (X.X.X.X/X):

read -p 'Type your POD network CIDR (X.X.X.X/X): ' POD_CIDR



# Pull images used by kubeadm

sudo kubeadm config images pull



# kubeadm init initialize the config.yaml configuration file:

sudo kubeadm init \
  --pod-network-cidr=${POD_CIDR} \
  --service-cidr=${SERVICE_CIDR} \
  --apiserver-advertise-address `hostname -i` \
  --node-name `hostname -f`

# Then you will get a message like this:

"
. . .

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.56.10:6443 --token lkjswx.5qzdsiba6p12e1yp \
    --discovery-token-ca-cert-hash sha256:011dffe0adcc6e8c815c216d4996e943d79d5f90c7c4720890e89f05264a77aa
"



# Hidden directory creation in home of the non-root user:

mkdir ~/.kube



# Copy admin.conf file and give the properly ownership:

sudo bash -c "
cat /etc/kubernetes/admin.conf > ~`whoami`/.kube/config
"



# Change user and group owner:

sudo chown `id -u`:`id -g` ~/.kube/config



# Environment variable for Calico version (X.Y) :

read -p 'Enter Calico version (X.Y): ' CALICO_VERSION



# Calico CNI plugin installation:

wget -qO - https://docs.projectcalico.org/manifests/calico.yaml | \
sed "s:192.168.0.0/16:${POD_CIDR}:g" | \
kubectl apply -f -



# Restart kubelet service:

sudo systemctl restart kubelet.service



# ============================================================================



# ============================
# ======= WORKER NODES =======
# ============================



# Enter the master node IP or hostname:

read -p 'Enter the master node (IP or hostname): ' K8S_MASTER



# Generate the SSH key:

ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa



# Copy the SSH key to Master node:

ssh-copy-id ${K8S_MASTER}



# Copy the .kube directory into the current node:

scp -r ${K8S_MASTER}:~/.kube .



# Join into the cluster:

# kubeadm join <master_host>:6443 --token <token> --discovery-token-ca-cert-hash <hash>

ssh ${K8S_MASTER} 'kubeadm token create --print-join-command' | \
xargs -i sudo bash -c "{}"



# Get the nodes of the cluster:

kubectl get nodes



#

kubectl create namespace nsfoo



# 

kubectl run foo --namespace=nsfoo --replicas=5 --port=8000 --image=nginx:alpine --labels='app=foo,env=prod'



#

kubectl port-forward deploy/web-server --namespace=nsfoo 8000:80 &



# ============================================================================
# Helm Installation
# ============================================================================

# Download Helm:
wget -c https://get.helm.sh/helm-v3.0.0-beta.3-linux-amd64.tar.gz -P /tmp



# 