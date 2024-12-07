# Patroni lab

| **Hostname** | **IP**         | **Role**                       |
|--------------|----------------|--------------------------------|
| pg-alpha     | 192.168.56.10  | PostgreSQL (primary) / Patroni |
| pg-beta      | 192.168.56.20  | PostgreSQL (standby) / Patroni |
| pg-gamma     | 192.168.56.30  | PostgreSQL (standby) / Patroni |
| haproxy      | 192.168.56.100 | HAProxy                        |
| etcd1        | 192.168.56.101 | ETCD                           |
| etcd2        | 192.168.56.102 | ETCD                           |
| etcd3        | 192.168.56.103 | ETCD                           |





```bash
cat << EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.56.70    vbhost.local    vbhost
192.168.56.10    alpha.local     alpha
192.168.56.20    beta.local      beta
192.168.56.30    gamma.local     gamma
192.168.56.100   haproxy.local   haproxy
192.168.56.101   etcd1.local     etcd1
192.168.56.102   etcd2.local     etcd2
192.168.56.103   etcd3.local     etcd3
EOF
```




```bash
host-confg.sh
```

