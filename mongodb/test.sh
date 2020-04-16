#!/bin/bash

"
MongoDB

Main config file: /etc/mongod.conf
Data directory: /var/lib/mongo
Log directory: /var/log/mongodb
System user: mongod
System group: mongod
"

# ============================================================================
# Installation
# ============================================================================




# Enmvironment variable for Mongo version
read -p 'Enter MongoDB version: ' MONGO_VERSION
export MONGO_VERSION="${MONGO_VERSION:-4.2}"



# Heredoc for Mongo repository file
cat << EOF > /tmp/mongodb-org-${MONGO_VERSION}.repo && \
sudo mv /tmp/mongodb-org-${MONGO_VERSION}.repo /etc/yum.repos.d/ && \
sudo chown root: /etc/yum.repos.d/mongodb-org-${MONGO_VERSION}.repo
[mongodb-org-${MONGO_VERSION}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\${releasever}/mongodb-org/\
${MONGO_VERSION}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc
EOF




# Update repository list
sudo dnf repolist



# Install MongoDB
sudo dnf install -y mongodb-org && sudo dnf clean all



# Edit the configuration file
sudo vim /etc/mongod.conf

"
coment or delete the line 'bindIp: ...'
add just below, in the same indentation 'bindIpAll: true' like this:

# network interfaces
net:
  port: 27017
  bindIpAll: true
"



# Enable and start immediately the MongoDB service
sudo systemctl enable --now mongod



# ============================================================================
# Enable Access Control
# ============================================================================
# Ref.: https://docs.mongodb.com/manual/tutorial/enable-authentication/



# Edit the configuration file
sudo vim /etc/mongod.conf



# Add these lines at the bottom of config file:
"
security:
    authorization: enabled
"



# MongoDB client
mongo


"
use admin

db.createUser(
    {
    user: 'admin',
    pwd: passwordPrompt(), // or cleartext password
    roles: [ {role: 'root', db: 'admin' }, 'readWriteAnyDatabase']
    }
)
"



# You can check that the user has been correctly created with this command:
"
db.auth('admin', passwordPrompt())
"



# Restart MongoDB service
sudo systemctl restart mongod



# ============================================================================
# Replication
# ============================================================================
# Ref.: https://docs.mongodb.com/manual/replication/
# Ref.: https://docs.mongodb.com/manual/tutorial/deploy-replica-set/



# Directory creation for security purposes (permission mode 700)
sudo mkdir -m 700 /var/lib/mongo/security



# Generate the keyfile
sudo su -c 'openssl rand -base64 756 > /var/lib/mongo/security/keyfile'



# Change its permission mode to 400
sudo chmod 400 /var/lib/mongo/security/keyfile



# Change ownership
sudo chown -R mongod: /var/lib/mongo/security



# Shell script for get the address of each node (except master node)
i=0

while :; do 
  read -p '[<Ctrl> + C to finish] - Enter hostname or IP adrress: ' NODE[i];
  let i+=1;
done



# Script for send the keyfile to worker nodes
for i in `seq 0 $((${#NODE[@]}-1))`; do
  echo -e "\n${NODE[$i]}\n"
  sudo rsync -av /var/lib/mongo/security root@${NODE[i]}:/var/lib/mongo/;
done



# Stop the MongoDB service
sudo systemctl stop mongod.service



# Edit the configuration file
sudo vim /etc/mongod.conf



# Add these lines at the bottom of config file:
"
replication:
  replSetName: 'rs0'

security:
  keyFile: /var/lib/mongo/security/keyfile
"



# Script for send the config file to worker nodes
for i in ${NODE[@]}; do
  echo -e "${i}\n"
  sudo rsync -av /etc/mongod.conf root@${i}:/etc/mongod.conf;
done



# Restart worker nodes
for i in ${NODE[@]}
do
  ssh root@${i} 'systemctl restart mongod'  
done



# Admin password
read -sp 'Enter the admin password: ' ADMIN_PASSWD



# Mongo client
mongo -u admin --eval 'rs.initiate()' -p ${ADMIN_PASSWD} admin



# Restart worker nodes
for i in ${NODE[@]};
do
  mongo -u admin --eval "rs.add('${i}')" -p ${ADMIN_PASSWD} admin;
done








# Restart MongoDB service

"
rs.initiate(
  {
    _id : 'rs0',
    members: [
      { _id : 0, host : 'mongo-01:27017' },
      { _id : 1, host : 'mongo-02:27017' },
      { _id : 2, host : 'mongo-03:27017' }
    ]
  }
)
"


rs0:SECONDARY> rs.slaveOk()


"
use db_teste

db.createUser(
    {
    user: 'user_teste',
    pwd: passwordPrompt(), // or cleartext password
    roles: [ {role: 'readWrite', db: 'db_teste' }],
    mechanisms: [ 'SCRAM-SHA-256' ]
    }
)
"