CREATE DATABASE db_types;

\c db_types

CREATE TABLE tb_int2 (f int2);

CREATE TABLE tb_int4 (f int4);

CREATE TABLE tb_int8 (f int8);

CREATE TABLE tb_text (f text);


CREATE OR REPLACE FUNCTION fc_random_between (int8, int8)
RETURNS int8 AS $$
BEGIN                                                          
     RETURN floor(random() * ($2 - $1 + 1) + $1)::int8;
END; $$ LANGUAGE PLPGSQL;

/*
smallint -32768 to +32767
integer -2147483648 to +2147483647
bigint -9223372036854775808 to +9223372036854775807
*/


WITH
t AS (
SELECT
    generate_series(1, 15000000) id_,
    fc_random_between(-32768, 32767)::text random_)
INSERT INTO tb_text (f) 
    SELECT random_ FROM t;


WITH
t AS (
SELECT
    generate_series(1, 15000000) id_,
    fc_random_between(2147483648, 9223372036854775807)::int8 random_)
INSERT INTO tb_int8 (f) 
    SELECT random_ FROM t;


WITH
t AS (
SELECT
    generate_series(1, 15000000) id_,
    fc_random_between(32768, 2147483647)::int4 random_)
INSERT INTO tb_int4 (f) 
    SELECT random_ FROM t;

WITH
t AS (
SELECT
    generate_series(1, 15000000) id_,
    fc_random_between(-32768, 32767)::int2 random_)
INSERT INTO tb_int2 (f) 
    SELECT random_ FROM t;


CREATE INDEX idx_int2 ON tb_int2 (f);

CREATE INDEX idx_int4 ON tb_int4 (f);

CREATE INDEX idx_int8 ON tb_int8 (f);

CREATE INDEX idx_text ON tb_text (f);







