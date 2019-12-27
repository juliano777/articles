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

#
ansible vb0 -b -u root -a 'whoami'

'
vb0 | CHANGED | rc=0 >>
root
'

# 
touch /tmp/foo.txt

#
ansible vb0 -m copy -a 'src=/tmp/foo.txt dest=/tmp/bar.xyz mode=600'

'
vb0 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": true,
    "checksum": "da39a3ee5e6b4b0d3255bfef95601890afd80709",
    "dest": "/tmp/bar.xyz",
    "gid": 1000,
    "group": "centos",
    "md5sum": "d41d8cd98f00b204e9800998ecf8427e",
    "mode": "0600",
    "owner": "centos",
    "secontext": "unconfined_u:object_r:user_home_t:s0",
    "size": 0,
    "src": "/home/centos/.ansible/tmp/ansible-tmp-1577477311.5657377-151019920460756/source",
    "state": "file",
    "uid": 1000
}
'

#
ansible vb0 -a 'ls -lh /tmp/bar.xyz'

'
vb0 | CHANGED | rc=0 >>
-rw-------. 1 centos centos 0 Dec 27 18:08 /tmp/bar.xyz
'

#
ansible-playbook first_playbook.yaml