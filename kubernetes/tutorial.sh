# Install packages:

yum install -y yum-utils device-mapper-persistent-data lvm2 ebtables ethtool



# First of all we need Docker:

wget -O - https://get.docker.com | bash



# What is your user to use Docker?:

read -p 'What is your user to use Docker? ' DOCKER_USER


# Add your user to Docker group:

usermod -aG docker ${DOCKER_USER}



# Configuration directory of Docker:

mkdir /etc/docker



# Setup Docker daemon:

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



# Enable and start Docker service:

systemctl enable --now docker.service



# Kubernetes repository file:

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



# Update repository list;

yum repolist -y



# Disable swap

# On /etc/fstab:

sed 's/\(.*swap\)/#\1/g' -i /etc/fstab

# Immediate, via command:

swapoff -a



# Disable and stop firewall:

systemctl disable --now firewalld



# Disable Selinux:

sed 's/SELINUX=.ermissive/SELINUX=disabled/g' -i /etc/selinux/config && \
setenforce 0



# Sysctl properties:

cat << EOF > /etc/sysctl.d/k8s.conf && sysctl --system
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF



# Packages of Kubernetes to install:

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes



# Clean up downloaded packages:

yum clean all



#

cat << EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS='--cgroup-driver=systemd'
EOF



#

kubeadm config images pull



# Type your network CIDR (X.X.X.X/X):

read -p 'Type your network CIDR (X.X.X.X/X): ' NET_CIDR



# kubeadm init initialize the config.yaml configuration file:

kubeadm init \
  --pod-network-cidr=${NET_CIDR} \
  --service-cidr=${NET_CIDR} \
  --ignore-preflight-errors=Swap \
  --apiserver-advertise-address `hostname -i` \
  --node-name `hostname -s`



# Enable and start kubelet:

systemctl enable --now kubelet



# Hidden directory creation in home of the non-root user:

su - ${DOCKER_USER} -c 'mkdir ~/.kube'



# Enable kubectl auto completion (needs bash-completion pre installed):

echo 'source <(kubectl completion bash)' >> /etc/profile.d/kubectl.sh




# ===== Cluster Configuration ================================================


# ==== Primary Node ==========================================================




#

cp -vi /etc/kubernetes/admin.conf `eval echo ~${DOCKER_USER}/.kube/config`



#

chown -R `id -u ${DOCKER_USER}`:`id -g ${DOCKER_USER}`\
    `eval echo ~${DOCKER_USER}/.kube`



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