# Inventory file
sudo bash -c 'cat << EOF > /etc/ansible/hosts
localhost ansible_connection=local

[virtualbox]
vb0  ansible_connection=ssh  ansible_user=centos
EOF'


# 
ansible vb0 -m ping
'
vb0 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
'

# 
ansible vb0 -a 'uname -r'
'
vb0 | CHANGED | rc=0 >>
5.4.1
'

#
ansible all -m ping
'
localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
vb0 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
'