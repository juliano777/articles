#!/bin/bash

"
MongoDB

Main config file: /etc/mongod.conf
Data directory: /var/lib/mongo
Log directory: /var/log/mongodb
System user: mongod
System group: mongod
Default port: 27017
"

# ============================================================================
# Installation
# ============================================================================




# Enmvironment variable for Mongo version (default: 4.2)
read -p 'Enter MongoDB version: ' MONGO_VERSION
export MONGO_VERSION="${MONGO_VERSION:-4.2}"



# Repository file creation
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



# Edit the configuration file, "net" session to listen at all addresses
sudo vim /etc/mongod.conf

"
net:
  port: 27017
  bindIpAll: true
"



# ============================================================================
# Enable Access Control
# ============================================================================
# Ref.: https://docs.mongodb.com/manual/tutorial/enable-authentication/



# Edit the configuration file (security session)
sudo vim /etc/mongod.conf

"
security:
    authorization: enabled
"



# Enable and start immediately the MongoDB service
sudo systemctl enable --now mongod



# MongoDB client (admin database)
mongo admin


"
db.createUser(
    {
    user: 'admin',
    pwd: passwordPrompt(),
    roles: [ {role: 'root', db: 'admin' }, 'readWriteAnyDatabase']
    }
)
"



# You can check that the user has been correctly created with this command:
"
db.auth('admin', passwordPrompt())
"



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
for i in ${NODE[@]}; do
  echo -e "\n${i}\n"
  sudo rsync -av /var/lib/mongo/security root@${i}:/var/lib/mongo/;
done



# Stop the MongoDB service
sudo systemctl stop mongod.service



# Edit the configuration file
sudo vim /etc/mongod.conf

"
security:
  authorization: enabled
  keyFile: /var/lib/mongo/security/keyfile

replication:
  replSetName: 'rs0'  
"



# Script for send the config file to worker nodes
for i in ${NODE[@]}; do
  echo -e "${i}\n"
  sudo rsync -av /etc/mongod.conf root@${i}:/etc/mongod.conf;
done



# Start MongoDB service at the master node
sudo systemctl start mongod.service



# Restart worker nodes
for i in ${NODE[@]}
do
  ssh root@${i} 'systemctl restart mongod'  
done



# Admin password
read -sp 'Enter the admin password: ' ADMIN_PASSWD



# Mongo client
mongo -u admin --eval 'rs.initiate()' -p ${ADMIN_PASSWD} admin



# Add worker nodes
for i in ${NODE[@]};
do
  mongo -u admin --eval "rs.add('${i}')" -p ${ADMIN_PASSWD} admin;
done



# User password
read -sp 'Enter the admin password: ' USER_PASSWD



# New user creation
mongo -u admin -p ${ADMIN_PASSWD} admin << EOF

// New database
use db_test

// New user
db.createUser(
    {
    user: 'user_test',
    pwd: '${USER_PASSWD}',
    roles: [ {role: 'readWrite', db: 'db_test' }],
    mechanisms: [ 'SCRAM-SHA-256' ]
    }
)

EOF



# Test user with a new collection
mongo \
  -u user_test \
  -p ${USER_PASSWD} \
  --eval "db.person.insert({'name': 'Ludwig', 'surname': 'van Beethoven'})" \
  db_test



# 
export QUERY="
// Enable queries in worker
rs.slaveOk()

// All results for the collection
db.person.find()
"



# Test workers nodes
for i in ${NODE[@]}
do
  echo "[ ${i} ]"
  mongo \
    --quiet \
    -u user_test \
    -p ${USER_PASSWD} \
    ${i}/db_test << EOF
    ${QUERY}
EOF
done