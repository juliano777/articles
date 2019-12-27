# (CentOS) Install Python 3:
sudo dnf install -y python3{,-setuptools} wget && sudo dnf clean all

# Install pip:
wget -O - https://bootstrap.pypa.io/get-pip.py | sudo python3

# Install Ansible
sudo pip3 install ansible

# Make Ansible configuration directory:
sudo mkdir /etc/ansible