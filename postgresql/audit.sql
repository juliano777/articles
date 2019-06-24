CREATE DATABASE db_audit;

\c db_audit

-- Table creations ==========================================================;

-- Original table of users

CREATE TABLE tb_user(
    id serial PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean DEFAULT TRUE);



-- Schema for the partitions;

CREATE SCHEMA sc_audit_partitions;

CREATE SCHEMA sc_audit;


-- Audit table of users (partitioned);

CREATE TABLE sc_audit.tb_user_audit(
    id int,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean NOT NULL,
    modif_ts TIMESTAMP WITH TIME ZONE NOT NULL,  -- Modification date
    modif_user VARCHAR(50) NOT NULL,  -- User who made the change
    op CHAR(1) NOT NULL)   -- Operation (INSERT: I, UPDATE: U, DELETE: D)
    PARTITION BY RANGE (modif_ts);







-- Functions to partitions ==================================================;

-- fc_aux_year_month --------------------------------------------------------;

/*
Auxiliary function - fc_aux_year_month

This function returns a set of 12 (twelve) tuples corresponding to the
months of the year.
Each row has 3 (three) fields:

year_month::text - A string with year and month
date_start::date - Date of first day of current month
date_end::date - Date of first day of next month

*/;

CREATE OR REPLACE FUNCTION fc_aux_year_month(year INT)
RETURNS TABLE (
               year_month text,
               date_start date,
               date_end date) AS $body$

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



-- fc_create_partition_range -------------------------------------------------;

/* 
Function - fc_create_partition_range

This function creates a range of partitions given a a year of start and year
of end.
 

*/;

CREATE OR REPLACE FUNCTION fc_create_partition_range(
    year_start int,
    year_end int,
    table_ text,
    part_ text,
    tablespace_ text DEFAULT 'pg_default'
    )
RETURNS TEXT AS $body$

DECLARE
    r record;
    sql_template text := $$
        CREATE TABLE IF NOT EXISTS %s_%s
            PARTITION OF %s
            FOR VALUES FROM ('%s') TO ('%s')
            TABLESPACE %s
    $$;
    sql text;    
    

BEGIN
    FOR i IN year_start .. year_end LOOP
        FOR r IN SELECT year_month, date_start, date_end
            FROM fc_aux_year_month(i) LOOP
            sql := format(
                sql_template, part_, r.year_month, table_, r.date_start,
                r.date_end, tablespace_);
            EXECUTE sql;              
        END LOOP;  
    END LOOP;

    RETURN table_;

END;$body$ LANGUAGE PLPGSQL;






































-- fc_tg_audit_user ---------------------------------------------------------;


CREATE OR REPLACE FUNCTION sc_audit.fc_tg_audit_user()
RETURNS TRIGGER AS $body$

DECLARE
    op CHAR(1) := left(TG_OP, 1);    

BEGIN
    IF (op IN ('I', 'U', 'D')) THEN
        INSERT INTO sc_audit.tb_user_audit (
            id, username, password, active, modif_ts, modif_user, op)
            VALUES
            (NEW.id, NEW.username, NEW.password, NEW.active, now(), 'foo', op); 

    END IF;

END;$body$ LANGUAGE PLPGSQL;


CREATE TRIGGER tg_audit_user
    AFTER INSERT OR UPDATE OR DELETE ON tb_user
    FOR EACH ROW EXECUTE PROCEDURE sc_audit.fc_tg_audit_user();




