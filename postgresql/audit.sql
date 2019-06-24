CREATE DATABASE db_audit;

\c db_audit

-- Table creations ==========================================================;

-- Original table of users

CREATE TABLE tb_user(
    id serial PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean DEFAULT TRUE);


-- Audit table of users (partitioned);

CREATE TABLE tb_user_audit(
    id int,
    name VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean NOT NULL,
    modif_ts TIMESTAMP WITH TIME ZONE NOT NULL,  -- Modification date
    modif_user VARCHAR(50) NOT NULL,  -- User who made the change
    op CHAR(1) NOT NULL)   -- Operation (INSERT: I, UPDATE: U, DELETE: D)
    PARTITION BY RANGE (modif_ts);



-- Schema for the partitions;

CREATE SCHEMA sc_partitions;



-- Functions to partitions ==================================================;

CREATE OR REPLACE FUNCTION fc_aux_year_month(year INT)
RETURNS TABLE (
               year_month text,
               date_start date,
               date_end date) AS $body$

/*
Auxiliary function - fc_aux_year_month

This function returns a set of 12 (twelve) tuples corresponding to the
months of the year.
Each row has 3 (three) fields:

year_month::text - A string with year and month
date_start::date - Date of first day of current month
date_end::date - Date of first day of next month

*/;

DECLARE
    sql varchar := $$
    WITH 
    t (data) AS (
    SELECT
        generate_series(
            '%s-01-01',
            '%s-12-01',
            '1 month'::interval)::date
    )
    SELECT
        to_char(data, 'yyyy_mm') AS year_month,
        data AS date_start,
        (data + '1 month'::interval)::date AS date_end

    FROM t;
    $$;

BEGIN

    sql := format(sql, year, year);

    RETURN QUERY EXECUTE sql;

END;$body$ LANGUAGE PLPGSQL;



CREATE OR REPLACE FUNCTION fc_create_partition_range(
    year_start int,
    year_end int,
    table_ text,
    schema_ text DEFAULT 'public',
    tablespace_ text DEFAULT 'pg_default')
RETURNS TEXT AS $body$

DECLARE
    r record;
    sql_template text := $$
        CREATE TABLE IF NOT EXISTS %s.%s_%s
            PARTITION OF %s
            FOR VALUES FROM ('%s') TO ('%s')
            TABLESPACE %s
    $$;
    sql text;    
    

BEGIN
    FOR i IN year_start .. year_end LOOP
        FOR r IN SELECT year_month, date_start, date_end FROM fc_aux_year_month(i) LOOP
            sql := format(sql_template, schema_, table_, r.year_month, table_,
                          r.date_start, r.date_end, tablespace_);
            EXECUTE sql;              
        END LOOP;  
    END LOOP;

    RETURN table_;

END;$body$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $body$
DECLARE
    v_old_data TEXT;
    v_new_data TEXT;
BEGIN
    /*  If this actually for real auditing (where you need to log EVERY action),
        then you would need to use something like dblink or plperl that could log outside the transaction,
        regardless of whether the transaction committed or rolled back.
    */
 
    /* This dance with casting the NEW and OLD values to a ROW is not necessary in pg 9.0+ */
 
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := ROW(OLD.*);
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.logged_actions (schema_name,table_name,user_name,action,original_data,new_data,query) 
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1),v_old_data,v_new_data, current_query());
        RETURN NEW;




