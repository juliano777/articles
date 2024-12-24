# TimescaleDB tutorial

## Preparations in the operating system

This tutorial will be guided by the assumption that your installation was via
the official PostgreSQL repository for Linux.
&nbsp;
[https://www.postgresql.org/download/linux](https://www.postgresql.org/download/linux)
&nbsp;
The following procedures will be described for Linux distributions based on
[RedHat](https://www.redhat.com) and [Debian](https://www.debian.org).
Some examples of distributions are described, but the concepts can be applied
to other distributions that are less well-know.

**Regardless of the Linux distro...**
&nbsp;
Get the major version of PostgreSQL:
```bash
PGMAJOR=`psql --version | awk '{print $(NF)}' | cut -f1 -d.`
```

Change the `shared_preload_libraries` parameter in `postgresql.conf` like
this:
```
shared_preload_libraries = 'timescaledb'
```
There may already be one or more pre-configured extensions in
`shared_preload_libraries`. In this case, just add a comma (`,`) after the
last one and then `timescaledb`:
```
shared_preload_libraries = 'other_extension,timescaledb'
```

### RedHat family

Compatible with:

- [**RedHat**](https://www.redhat.com)
- [**Fedora**](https://fedoraproject.org)
- [**AlmaLinux**](https://almalinux.org)
- [**Rocky Linux**](https://rockylinux.org)
- [**Scientific Linux**](https://scientificlinux.org)
- [**CentOS** (deprecated)](https://centos.org)


Installing the extension via RedHat package:
```bash
dnf install -y timescaledb_${PGMAJOR}
```

As explained previously, change the `postgresql.conf` file of your instance:
```bash
vim /var/lib/pgsql/${PGMAJOR}/data/postgresql.conf
```

restart the PostgreSQL service:
```bash
systemctl restart postgresql-${PGMAJOR}.service
```

### Debian family

Compatible with:

- [**Debian**](https://www.debian.org)
- [**Ubuntu**](https://ubuntu.com)
- [**Linux Mint**](https://linuxmint.com)
- [**PopOS**](https://pop.system76.com)
- [**Zorin OS**](https://zorin.com/os)

Installing the extension via RedHat package:
```bash
apt install -y postgresql-${PGMAJOR}-timescaledb
```

As explained previously, change the `postgresql.conf` file of your instance:
```bash
vim /etc/postgresql/${PGMAJOR}/main/postgresql.conf/postgresql.conf
```

restart the PostgreSQL service:
```bash
systemctl restart postgresql@${PGMAJOR}-main.service
```

## SQL


Creating the test database and then accessing it:
```bash
# Database creation
createdb db_timescale

# Database connection
psql db_timescale
```

```sql
-- Create
CREATE SCHEMA sc_timescaledb;

-- ENABLE TimescaleDB extension on database
CREATE EXTENSION IF NOT EXISTS timescaledb SCHEMA sc_timescaledb;

/*
Criar uma tabela de séries temporais: Usaremos uma tabela chamada sensor_data para armazenar as leituras de temperatura e umidade.
*/
CREATE TABLE tb_sensor_data (
    colletciontime TIMESTAMPTZ NOT NULL,   -- Marca temporal
    sensor_id INT NOT NULL,      -- Identificador do sensor
    temperature FLOAT,           -- Temperatura registrada
    humidity FLOAT               -- Umidade registrada
);

/*
Transformar a tabela em uma hypertable: O TimescaleDB utiliza o conceito de hypertables, que particionam automaticamente os dados por tempo.
*/

SELECT sc_timescaledb.create_hypertable('tb_sensor_data', 'colletciontime');

      create_hypertable
-----------------------------
 (1,public,tb_sensor_data,t)

\d tb_sensor_data
                       Table "public.tb_sensor_data"
     Column     |           Type           | Collation | Nullable | Default
----------------+--------------------------+-----------+----------+---------
 colletciontime | timestamp with time zone |           | not null |
 sensor_id      | integer                  |           | not null |
 temperature    | double precision         |           |          |
 humidity       | double precision         |           |          |
Indexes:
    "tb_sensor_data_colletciontime_idx" btree (colletciontime DESC)
Triggers:
    ts_insert_blocker BEFORE INSERT ON tb_sensor_data FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker()

-- Insert some data
INSERT INTO tb_sensor_data (colletciontime, sensor_id, temperature, humidity)
VALUES
('2024-12-24 08:00:00', 1, 22.5, 60.0),
('2024-12-24 08:01:00', 1, 22.6, 59.8),
('2024-12-24 08:02:00', 1, 22.7, 59.5);

-- Obter todas as leituras de um intervalo de tempo:

SELECT *
FROM sensor_data
WHERE time >= '2024-12-24 08:00:00'
  AND time <= '2024-12-24 08:02:00';

-- Calcular a média de temperatura em um intervalo:

SELECT AVG(temperature) AS avg_temperature
FROM sensor_data
WHERE time >= '2024-12-24 08:00:00'
  AND time <= '2024-12-24 08:10:00';

-- Detectar tendências (valores anômalos): Identificar temperaturas acima de 25°C.

SELECT time, temperature
FROM sensor_data
WHERE temperature > 25.0;

-- Agregação contínua (usando uma continuous aggregate): Calcule a temperatura média por hora.

CREATE MATERIALIZED VIEW hourly_avg_temperature
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS hour,
       AVG(temperature) AS avg_temperature
FROM sensor_data
GROUP BY hour;

-- Agora, você pode consultar a visualização:

SELECT * FROM hourly_avg_temperature
WHERE hour >= '2024-12-24 00:00:00';















