#!/bin/bash

PKG='wget gcc make pkg-config libsystemd-dev libevent-dev libssl-dev'

apt install -y ${PKG} && apt clean

VERSION=1.15.0

URL="http://www.pgbouncer.org/downloads/files/\
${VERSION}/pgbouncer-${VERSION}.tar.gz"

cd /tmp

wget ${URL}

tar xvf pgbouncer-${VERSION}.tar.gz

cd pgbouncer-${VERSION}

./configure --prefix /usr/local/pgbouncer --with-pam --with-systemd --with-openssl

make && make install

mkdir -m 0700 /{etc,var/log}/pgbouncer

echo '"postgres" ""' > /etc/pgbouncer/userlist.txt

cat << EOF > /etc/pgbouncer/pgbouncer.ini
[databases]
mydb = host=127.0.0.1 port=5432 dbname=mydb
 
[pgbouncer]
listen_port = 6432
listen_addr = 127.0.0.1
auth_type = trust
auth_file = /etc/pgbouncer/userlist.txt
logfile = /var/log/pgbouncer/pgbouncer.log
admin_users = postgres
pool_mode = transaction
default_pool_size=90
max_client_conn=3000
EOF

chown -R postgres: /{etc,var/log}/pgbouncer

cat << EOF > /etc/systemd/system/pgbouncer.service 
[Unit]
Description=connection pooler for PostgreSQL
Documentation=man:pgbouncer(1)
Documentation=https://www.pgbouncer.org/
After=network.target
#Requires=pgbouncer.socket

[Service]
Type=notify
User=postgres
ExecStart=/usr/local/pgbouncer/bin/pgbouncer /etc/pgbouncer/pgbouncer.ini
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
#LimitNOFILE=1024

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now pgbouncer.service

apt purge -y ${PKG}
