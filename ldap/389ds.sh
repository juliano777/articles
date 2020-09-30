# sysctl configurations
cat << EOF > /etc/sysctl.d/ldap_389ds.conf
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65535
EOF



# Apply configurations
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




# Interactive configuration
dscreate interactive

"
Enter system's hostname [vb-08.local]: 

Enter the instance name [vb-08]: 

Enter port number [389]: 

Create self-signed certificate database [yes]: 

Enter secure port number [636]: 

Enter Directory Manager DN [cn=Directory Manager]: 

Enter the Directory Manager password: 
Password must be at least 8 characters long

Enter the Directory Manager password: 
Password must be at least 8 characters long

Enter the Directory Manager password: 
Confirm the Directory Manager Password: 

Enter the database suffix (or enter "none" to skip) [dc=vb-08,dc=local]: 

Create sample entries in the suffix [no]: 

Create just the top suffix entry [no]: yes

Do you want to start the instance after the installation? [yes]: 

Are you ready to install? [no]: yes
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


read -s MYPWD && pwdhash -s SSHA512 ${MYPWD}



dsconf -D "cn=Directory Manager" ldap://vb-08.local plugin list | fgrep Member

Enter password for cn=Directory Manager on ldap://vb-08.local: 
Auto Membership Plugin
MemberOf Plugin



dsconf -D "cn=Directory Manager" ldap://vb-08.local plugin memberof enable
Enter password for cn=Directory Manager on ldap://vb-08.local: 
Enabled plugin 'MemberOf Plugin'


systemctl restart dirsrv@vb-08.service

ldapmodify -xh vb-08.local -D 'cn=Directory Manager' -W -f arquivo.ldif

https://www.golinuxcloud.com/ldap-client-rhel-centos-8/

https://tylersguides.com/guides/configuring-ldap-authentication-on-centos-8/