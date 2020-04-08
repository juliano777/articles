#!/bin/bash

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
