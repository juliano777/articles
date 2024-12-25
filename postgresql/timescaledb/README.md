# TimescaleDB tutorial

## O que são séries temporais?

São dados coletados em sequência, registrados ao longo do tempo e ordenados
cronologicamente.\
Cada registro é um ponto de dado que representa um instante específico no
tempo, normalmente com intervalos regulares. Dessa forma então torna facilita
a análise de uma variável ao longo do tempo e identificar tendências, padrões
e outras características. O que ajuda muito numa tomada de decisão.\
Uma série temporal tem basicamente dois elementos; o momento (tempo) e o valor
naquele instante.\
Resumidamente, é um conjunto de pontos de dados, em que cada um é associado
a um momento único de tempo.

### Características principais de séries temporais

- **Dependência temporal**\
  Não há independência de valores em uma série temporal. Para uma análise
  correta de um registro é preciso olhar para seus valores anteriores.
  Exemplo: o valor de uma ação em um determinado momento.

- **Periodicidade**\
  Pode acontecer de forma regular, como um sensor de temperatura de uma
  máquina que faz seus registros a cada minuto.
  Pode também acontecer de forma irregular, ou seja, não seguem um intervalo
  fixo e previsível, são eventos registrados apenas quando ocorrem. Registros
  de acesso é um exemplo disso.

- **Ordem cronológica**\
  A sequência dos registros é importante, bem como o dado de tempo é
  indispensável, pois sem essa informação perde o sentido.

## TimescaleDB

TimescaleDB é uma extensão criada e mantida pela
[Timescale](https://www.timescale.com/).  
É um projeto open-source, cuja licença é a Apache 2.0 e seu código-fonte está
disponível no Github em 
[https://github.com/timescale/timescaledb](https://github.com/timescale/timescaledb).\
Seu objetivo é prover uma solução que possibilita cargas de trabalho de séries
temporais, aumentando o desempenho de ingestão, armazenamento, consulta e
análise.\
Documentação oficial: [https://docs.timescale.com](https://docs.timescale.com/)

### Características do TimescaleDB

#### Particionamento de tabelas dinâmico e automatizado: hypertables

Hypertables são tabelas PostgreSQL que particionam seus dados por tempo.\
A forma de interação com esse tipo de tabela é igual a uma tabela comum do
PostgreSQL, porém com recursos extras que tormam a forma de manejar dados de
séries temporais de uma forma mais fácil e com uma performance melhor.

#### Armazenamento híbrido linha-colunar

Com esse recurso consegue-se até 95% de compressão em dados colunares. O que
consequentemente economiza custos de armazenamento ao mesmo tempo que as
consultas têm alta performance (muito mais do que o padrão).

#### Agregações contínuas

Dados de séries temporais crescem muito rápido e ao fazer agregações de dados 
para sumarização pode se tornar algo muito devagar.\
Com agregações contínuas faz com que essa tarefa se torne muito mais rápida.\
Agregações contínus são um tipo de hypertable que são atualizadas
automaticamente em background conforme novos dados são adicionados ou ao
modificar dados antigos.

#### Funções especializadas em análises

Essas funções são chamadas de hyperfunctions, as quais executam consultas
críticas em séries temporais para extrair informações significativas.


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

## Prática com comandos SQL

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
    temperature numeric(3, 1),           -- Temperatura registrada
    humidity numeric(3, 1)               -- Umidade registrada
);

CREATE TABLE tb_sensor_data_hyper (
    colletciontime TIMESTAMPTZ NOT NULL,   -- Marca temporal
    sensor_id INT NOT NULL,      -- Identificador do sensor
    temperature numeric(3, 1),           -- Temperatura registrada
    humidity numeric(3, 1)               -- Umidade registrada
);

/*
Transformar a tabela em uma hypertable: O TimescaleDB utiliza o conceito de hypertables, que particionam automaticamente os dados por tempo.
*/
SELECT sc_timescaledb.create_hypertable('tb_sensor_data_hyper', 'colletciontime');

         create_hypertable         
-----------------------------------
 (1,public,tb_sensor_data_hyper,t)


CREATE UNLOGGED TABLE ut_sensor_data (
    colletciontime TIMESTAMPTZ NOT NULL,   -- Marca temporal
    sensor_id INT NOT NULL,      -- Identificador do sensor
    temperature numeric(3, 1),           -- Temperatura registrada
    humidity numeric(3, 1)               -- Umidade registrada
);





CREATE OR REPLACE FUNCTION fc_randint(
    IN lower_lim int default 1,
    IN upper_lim int default 10,
    OUT randint int    
) RETURNS int AS $body$
DECLARE
    msg text := ('The lower limit must be less than or equal to'
    ' the upper limit');
BEGIN
    -- Checks if the limits are valid
    IF lower_lim > upper_lim THEN
        RAISE EXCEPTION '%', msg;
    END IF;

    -- Gera um número aleatório no intervalo
    randint := trunc(random() * (upper_lim - lower_lim + 1)) + lower_lim;
END;
$body$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fc_randfloat(
    IN lower_lim numeric default 0.1,
    IN upper_lim numeric default 10,
    OUT randfloat numeric    
) RETURNS numeric AS $body$
DECLARE
    msg text := ('The lower limit must be less than or equal to'
    ' the upper limit');
BEGIN
    -- Checks if the limits are valid
    IF lower_lim > upper_lim THEN
        RAISE EXCEPTION '%', msg;
    END IF;

    -- Gera um número aleatório no intervalo
    randfloat := (random() * (upper_lim - lower_lim) + lower_lim)::numeric(3, 1);
END;
$body$
LANGUAGE plpgsql;

INSERT INTO ut_sensor_data (colletciontime, sensor_id, temperature, humidity)
SELECT
  ('2021-05-31 00:00:00'::timestamp + 
    (n * '1 second'::interval)),  -- colletciontime
  fc_randint(1, 10),  -- sensor_id
  fc_randfloat(20, 30),  -- temperature
  fc_randfloat(40, 70) -- humidity
FROM generate_series(0, 9999999) as n;

\timing on

INSERT INTO tb_sensor_data_hyper (colletciontime, sensor_id, temperature, humidity)
SELECT  colletciontime, sensor_id, temperature, humidity
FROM ut_sensor_data;

Time: 21996.522 ms (00:21.997)

INSERT INTO tb_sensor_data (colletciontime, sensor_id, temperature, humidity)
SELECT  colletciontime, sensor_id, temperature, humidity
FROM ut_sensor_data;







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

SELECT count(*)
FROM tb_sensor_data_hyper
WHERE colletciontime >= '2021-06-01 08:00:00'
  AND colletciontime <= '2021-07-10 08:02:00';

SELECT count(*)
FROM tb_sensor_data
WHERE colletciontime >= '2021-06-01 08:00:00'
  AND colletciontime <= '2021-07-10 08:02:00';

-- Calcular a média de temperatura em um intervalo:

SELECT AVG(temperature) AS avg_temperature
FROM tb_sensor_data_hyper
WHERE colletciontime >= '2021-06-01 08:00:00'
  AND colletciontime <= '2021-07-10 08:02:00';

SELECT AVG(temperature) AS avg_temperature
FROM tb_sensor_data
WHERE colletciontime >= '2021-06-01 08:00:00'
  AND colletciontime <= '2021-07-10 08:02:00';

-- Detectar tendências (valores anômalos): Identificar temperaturas acima de 25°C.

SELECT time, temperature
FROM sensor_data
WHERE temperature > 25.0;

-- Agregação contínua (usando uma continuous aggregate): Calcule a temperatura média por hora.

CREATE MATERIALIZED VIEW hourly_avg_temperature
WITH (timescaledb.continuous) AS
SELECT sc_timescaledb.time_bucket('1 hour', colletciontime) AS hour,
       AVG(temperature) AS avg_temperature
FROM tb_sensor_data_hyper
GROUP BY hour;

-- Agora, você pode consultar a visualização:

SELECT * FROM hourly_avg_temperature
WHERE hour >= '2024-12-24 00:00:00';
```

### Resumindo: por que utilizar o TimescaleDB?

A questão do desempenho é crucial para qualquer sistema gerenciador de banco
de dados e com o uso de hypertables que otimizam consutlas em intervalos de
tempo se tornam ideias para lidar com grandes volumes de dados.\
Deve-se ressaltar também a forma simplificada para se fazer análises com as
hyperfunctions.\
Por fim o fator escalabilidade, devido ao particionamento automático das
hypertables, a extensão TimescaleDB gerencia dados históricos de forma
eficiente.

















