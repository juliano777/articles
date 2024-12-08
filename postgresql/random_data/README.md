## Random data

Create a new database:
```sql
CREATE DATABASE db_types;
```

Connect to this new database:
```
\c db_types
```

Create some tables regarding its test types:
```sql
-- smallint
CREATE TABLE tb_int2 (f int2);

-- integer
CREATE TABLE tb_int4 (f int4);

-- bigint
CREATE TABLE tb_int8 (f int8);

-- text
CREATE TABLE tb_text (f text);
```

Create a function that generates random numbers:
```sql
-- fc_random_between (first_integer, second_integer)
CREATE OR REPLACE FUNCTION fc_random_between (int8, int8)
RETURNS int8 AS
$$
BEGIN                                                          
     RETURN floor(random() * ($2 - $1 + 1) + $1)::int8;
END;
$$
LANGUAGE PLPGSQL;
```

| **Integer type** | **Range of value**                               |
|------------------|--------------------------------------------------|
| `smallint`       | `-32768` to `+32767`                             |
| `integer`        | `-2147483648` to `+2147483647`                   |
| `bigint`         | `-9223372036854775808` to +`9223372036854775807` |


Generate data to each table:
```sql
-- Table text
WITH
t AS (
SELECT
    generate_series(1, 150000000) id_,
    fc_random_between(-32768, 32767)::text random_)
INSERT INTO tb_text (f) 
    SELECT random_ FROM t;

-- Table bigint
WITH
t AS (
SELECT
    generate_series(1, 150000000) id_,
    fc_random_between(2147483648, 9223372036854775807)::int8 random_)
INSERT INTO tb_int8 (f) 
    SELECT random_ FROM t;

-- Table integer
WITH
t AS (
SELECT
    generate_series(1, 150000000) id_,
    fc_random_between(32768, 2147483647)::int4 random_)
INSERT INTO tb_int4 (f) 
    SELECT random_ FROM t;

-- Table smallint
WITH
t AS (
SELECT
    generate_series(1, 150000000) id_,
    fc_random_between(-32768, 32767)::int2 random_)
INSERT INTO tb_int2 (f) 
    SELECT random_ FROM t;
```    

Create indexes:
```sql
CREATE INDEX idx_int2 ON tb_int2 (f);

CREATE INDEX idx_int4 ON tb_int4 (f);

CREATE INDEX idx_int8 ON tb_int8 (f);

CREATE INDEX idx_text ON tb_text (f);
```

