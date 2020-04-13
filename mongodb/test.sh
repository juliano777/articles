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
export MONGO_VERSION='4.2'



# Heredoc for Mongo repository file
cat << EOF > /etc/yum.repos.d/mongodb-org-${MONGO_VERSION}.repo
[mongodb-org-${MONGO_VERSION}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\${releasever}/mongodb-org/${MONGO_VERSION}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc
EOF



# Update repository list
dnf repolist



# Install MongoDB
dnf install -y mongodb-org && dnf clean all



# Edit the configuration file
vim /etc/mongod.conf

"
coment the line 'bindIp: ...'
add just below, in the same indentation 'bindIpAll: true'
"



# Enable and start immediately the MongoDB service
systemctl enable --now mongod



# ============================================================================
# Enable Access Control
# ============================================================================
# Ref.: https://docs.mongodb.com/manual/tutorial/enable-authentication/



# Edit the configuration file
vim /etc/mongod.conf



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
    roles: [ {role: 'userAdminAnyDatabase', db: 'admin' }, 'readWriteAnyDatabase']
    }
)
"



# You can check that the user has been correctly created with this command:
"
db.auth('admin', passwordPrompt())
"



# Restart MongoDB service
systemctl restart mongod



# ============================================================================
# Replication
# ============================================================================
# Ref.: https://docs.mongodb.com/manual/replication/
# Ref.: https://docs.mongodb.com/manual/tutorial/deploy-replica-set/


sudo mkdir -m 700 /var/lib/mongo/security
sudo su -c 'openssl rand -base64 756 > /var/lib/mongo/security/keyfile'
sudo chmod 400 /var/lib/mongo/security/keyfile
sudo chown -R mongod: /var/lib/mongo/security
sudo rsync -av /var/lib/mongo/security root@mongo-03:/var/lib/mongo/
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

systemctl start mongod







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