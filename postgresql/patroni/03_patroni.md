```bash
RH_VERSION=`grep -F 'VERSION_ID' /etc/os-release | \
    tr -d \" | cut -f2 -d= |  cut -f1 -d.`
```

```bash
URL="https://download.postgresql.org/pub/repos/yum/reporpms/\
EL-${RH_VERSION}-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
```

```bash
dnf install -y ${URL}
```

```bash
dnf config-manager --set-enabled  pgdg-rhel${RH_VERSION}-extras
```

```bash
dnf install -y patroni patroni-etcd
```

```bash
mkdir -pm 0700 /var/lib/pgsql/patroni
chown postgres:postgres /var/lib/pgsql/patroni
```






```bash
vim /etc/patroni/patroni.yml
```

```yaml
scope: postgres
namespace: /db/
name: pg1

restapi:
    listen: 192.168.56.10:8008
    connect_address: 192.168.56.10:8008

etcd3:
    host: 192.168.56.101:2379

bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 10
        maximum_lag_on_failover: 1048576
        postgresql:
            use_pg_rewind: true

    initdb:
    - encoding: UTF8
    - data-checksums

    pg_hba:
    - host replication user_patroni 127.0.0.1/32 scram-sha-256
    - host replication user_patroni 192.168.56.10/32 scram-sha-256
    - host replication user_patroni 192.168.56.20/32 scram-sha-256
    - host replication user_patroni 192.168.56.30/32 scram-sha-256
    - host all all 0.0.0.0/0 scram-sha-256

    users:
        admin:
            password: admin
            options:
                - createrole
                - createdb

postgresql:
    listen: 192.168.56.10:5432
    connect_address: 192.168.56.10:5432
    data_dir: /var/lib/pgsql/patroni
    pgpass: /var/lib/pgsql/.pgpass
    authentication:
        replication:
            username: user_patroni
            password: password
        superuser:
            username: postgres
            password: password
        rewind:
            username: postgres
            password: password

    bin_dir: /usr/pgsql-15/bin

    parameters:
        unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```
