CREATE DATABASE db_audit;

\c db_audit

CREATE TABLE tb_user(
    id serial PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean DEFAULT TRUE);

CREATE TABLE tb_user_audit (
