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



# Edit the configuration file
vim /etc/mongod.conf



# Add these lines at the bottom of config file:
"
replication:
    replSetName: 'rs0'
"



# Restart MongoDB service
systemctl restart mongod

rs.add( { host: 'mongo-02.local:27017', priority: 0, votes: 0 } )