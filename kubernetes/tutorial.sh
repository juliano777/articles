# Install packages:

sudo yum install -y \
  yum-utils device-mapper-persistent-data lvm2 ebtables ethtool



# First of all we need Docker:

wget -O - https://get.docker.com | sudo bash



# Add your user to Docker group:

sudo usermod -aG docker `whoami`



# Configuration directory of Docker:

sudo mkdir /etc/docker



# Setup Docker daemon:

sudo bash -c 'cat << EOF > /etc/docker/daemon.json
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
EOF'



# Enable and start Docker service:

sudo systemctl enable --now docker.service



# Kubernetes repository file:

sudo bash -c 'cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg \
https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'



# Update repository list;

sudo yum repolist -y



# Disable swap

# On /etc/fstab:

sudo sed 's/\(.*swap\)/#\1/g' -i /etc/fstab

# Immediate, via command:

sudo swapoff -a



# Disable and stop firewall:

sudo systemctl disable --now firewalld



# Disable Selinux:

sudo sed 's/SELINUX=.ermissive/SELINUX=disabled/g' -i /etc/selinux/config && \
setenforce 0



# Sysctl properties:

sudo bash -c 'cat << EOF > /etc/sysctl.d/k8s.conf && sysctl --system
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'



# Packages of Kubernetes to install:

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes  # master

sudo yum install -y kubelet --disableexcludes=kubernetes  # nodes



# Clean up downloaded packages:

sudo yum clean all



#

sudo bash -c 'cat << EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS='--cgroup-driver=systemd'
EOF'



#

sudo kubeadm config images pull



# Type your network CIDR (X.X.X.X/X):

read -p 'Type your network CIDR (X.X.X.X/X): ' NET_CIDR



# Type your network POD network CIDR (X.X.X.X/X):

read -p 'Type your POD network CIDR (X.X.X.X/X): ' POD_CIDR



# Kubernetes version:

K8S_VERSION=`kubectl version --short 2> /dev/null | \
  fgrep Client | awk '{print $(NF)}'`



# kubeadm init initialize the config.yaml configuration file:

sudo kubeadm init \
  --kubernetes-version ${K8S_VERSION} \
  --pod-network-cidr=${POD_CIDR} \
  --service-cidr=${NET_CIDR} \
  --apiserver-advertise-address `hostname -i` \
  --node-name `hostname -f`



# Create aditional file for service kubelet:

sudo bash -c "mkdir /etc/systemd/system/kubelet.service.d 2> /dev/null ; \
cat << EOF > /etc/systemd/system/kubelet.service.d/11-cgroups.conf
[Service]

CPUAccounting=true
MemoryAccounting=true
EOF
"



# 

sudo systemctl daemon-reload



# Enable and start kubelet:

sudo systemctl enable --now kubelet



# Hidden directory creation in home of the non-root user:

mkdir ~/.kube



# Copy admin.conf file and give the properly ownership:

sudo bash -c "cat /etc/kubernetes/admin.conf > ~`whoami`/.kube/config"

sudo chown `id -u`:`id -g` ~/.kube/config



# Environment variable for Calico version (X.Y) :

read -p 'Enter Calico version (X.Y): ' CALICO_VERSION



# Calico CNI plugin installation:

wget -qO - https://docs.projectcalico.org/v${CALICO_VERSION}/\
manifests/calico.yaml | sed "s:192.168.0.0/16:${POD_CIDR}:g" | \
kubectl apply -f -



# Restart kubelet service:

sudo systemctl restart kubelet.service



# Enable kubectl auto completion (needs bash-completion pre installed):

echo 'source <(kubectl completion bash)' | sudo tee /etc/profile.d/kubectl.sh

sudo chmod +x /etc/profile.d/kubectl.sh

source /etc/profile.d/kubectl.sh




# ===== Cluster Configuration ================================================


# ==== Primary Node ==========================================================






#

kubeadm token delete `kubeadm token list | fgrep -v 'TOKEN' |\
    awk '{print $1}'`



# 

kubeadm token create --print-join-command



#

su - ${DOCKER_USER} -c "kubectl apply -f \
    https://cloud.weave.works/k8s/net?k8s-version=\
`kubectl version | base64 | tr -d '\n'`"





# ==== Secondary Nodes =======================================================


kubeadm join 192.168.56.10:6443 \
    --token 6z0y76.dsmf3fntbmrceya4 \
    --discovery-token-ca-cert-hash \
    sha256:c879596b560356aa942031fded10b824c0f10a4c44299176386c2d874465daa4


# ==== Primary Node ==========================================================

#

su - ${DOCKER_USER} -c 'kubectl get nodes'



#

kubeadm token list | fgrep -v 'TOKEN' | awk '{print $1}'



#

kubeadm token create --print-join-command



#

kubeadm join 192.168.56.10:6443 --token z2wgjs.78r5r84gfvbs26t6 \
    --discovery-token-ca-cert-hash sha256:d5daa632a744257d346b754cfdb21f0d6ecdf080536b7d06a15c06ffef4d8605