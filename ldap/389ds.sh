#!/bin/bash

# sysctl configurations
cat << EOF > /etc/sysctl.d/ldap_389ds.conf
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65535
EOF



# Applay configurations
sysctl -p /etc/sysctl.d/*



# Edit security limits file
vim /etc/security/limits.conf


"
*       soft    nofile  8192
*       hard    nofile  8192

# End of file
"



# Add LDAP Admin Group
groupadd -r ldapadmin



# Add LDAP Admin User
useradd -r -g ldapadmin \
	-s /bin/bash \
	-k /etc/skel \
	-c 'LDAP Admin' \
	-md /var/lib/ldap ldapadmin




# Install 389 DS Server, OpenLDAP clients and clean all downloaded packages
dnf install -y epel-release
dnf update epel-release
dnf module install -y 389-directory-server:stable/default
dnf install -y openldap-clients
dnf clean all




# 
dscreate interactive

"
Install Directory Server (interactive mode)
===========================================

Enter system's hostname [ldap.local]: vb-08.local

Enter the instance name [vb-08]: ldap01

Enter port number [389]:

Create self-signed certificate database [yes]: yes

Enter secure port number [636]:

Enter Directory Manager DN [cn=Directory Manager]:

Enter the Directory Manager password:
Confirm the Directory Manager Password:

Enter the database suffix (or enter "none" to skip) [dc=vb-08,dc=local]:

Create sample entries in the suffix [no]: yes

Do you want to start the instance after the installation? [yes]: yes

Are you ready to install? [no]: yes
Starting installation...
Completed installation for ldap01
"



# Check the ldap instance name

dsctl --list

"
slapd-ldap01
"



# Confirm that instance is running 
dsctl slapd-ldap01 status

'
Instance "ldap01" is running
'



# Check your ldap instance status 
systemctl status dirsrv@ldap01.service | fgrep Active

"
Active: active (running) since Mon 2020-09-07 12:00:12 -03; 4min 19s ago
"



# Enable and start cockpit service
systemctl enable --now cockpit.service



# 
ldapsearch -xb 'dc=vb-08,dc=local'

'
. . .
'



# 




"
Open up your preferred web browser and access the cockpit web interface by navigating to http://your_server_ip:9090."
