CREATE DATABASE db_audit;

\c db_audit

CREATE TABLE tb_user(
    id serial PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean DEFAULT TRUE);

CREATE TABLE tb_user_audit(
    id int,
    name VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean,
    modif_ts TIMESTAMP WITH TIME ZONE,  -- Modification date
    op_type CHAR(1))   -- Operation type (INSERT: I, UPDATE: U, DELETE: D)
    PARTITION BY RANGE (modif_ts);

I
U
D

