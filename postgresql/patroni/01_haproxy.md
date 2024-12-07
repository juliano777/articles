Installation  
```bash
dnf install -y haproxy && dnf clean all
```
  
Configuration
```bash
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.original
```

Configure syslog for HAProxy

To to have these messages end up in `/var/log/haproxy.log` you will need:  
  
1) configure syslog to accept network log events.  
   This is done by adding the '`-r`' option to the `SYSLOGD_OPTIONS` in `/etc/sysconfig/syslog`.  
  
2) configure local2 events to go to the `/var/log/haproxy.log` file.  
A line like the following can be added to `/etc/sysconfig/syslog`: 

```
local2.*                       /var/log/haproxy.log
```
   
```bash
cat << EOF > /etc/rsyslog.d/99-haproxy.conf
\$AddUnixListenSocket /var/lib/haproxy/dev/log

# Send HAProxy messages to a dedicated logfile
:programname, startswith, "haproxy" {
  /var/log/haproxy.log
  stop
}
EOF
```
  
```bash
cat << EOF > /usr/lib/tmpfiles.d/haproxy.conf
f /var/log/haproxy.log  0664 haproxy haproxy
d /var/lib/haproxy      0750 haproxy haproxy
d /var/lib/haproxy/dev  0750 haproxy haproxy
EOF
```  
  
```bash
systemd-tmpfiles --create
```  
  
Restart rsyslog service  
```bash
systemctl restart rsyslog.service
```

```bash
cat << EOF > /etc/haproxy/haproxy.cfg
# Port 5000 for Primary Connections (Read-Write)
# Port 5001 for Standby Connections (Read-Only)

global  # Global session
    maxconn 100  # Maximum allowed connections
    log /dev/log local0
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen pgReadWrite 
    bind *:5000
    option pgsql-check user user_tux
    default-server inter 3s fall 3
    server pg_alpha alpha:5432 check port 5432
    server pg_beta beta:5432 check port 5432 backup
    server pg_gamma gamma:5432 check port 5432 backup

listen pgReadOnly
    bind *:5001
    mode tcp
    balance roundrobin
    option tcp-check
    default-server inter 3s fall 3
    server pg_alpha alpha:5432 check port 5432
    server pg_beta beta:5432 check port 5432
    server pg_gamma gamma:5432 check port 5432

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

# Configuration for Standby Node Sync
listen haproxy-sync
    bind *:7000
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    server haproxy1 192.168.56.101:7000 check inter 5000 rise 2 fall 3
    server haproxy2 192.168.56.102:7000 check inter 5000 rise 2 fall 3

EOF
```
  
```bash
systemctl enable --now haproxy.service
```
