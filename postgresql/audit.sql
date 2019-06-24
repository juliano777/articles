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
    active boolean NOT NULL,
    modif_ts TIMESTAMP WITH TIME ZONE NOT NULL,  -- Modification date
    modif_user VARCHAR(50) NOT NULL,  -- User who made the change
    op CHAR(1) NOT NULL)   -- Operation (INSERT: I, UPDATE: U, DELETE: D)
    PARTITION BY RANGE (modif_ts);



CREATE OR REPLACE FUNCTION fc_year_month(year INT)
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
        FOR r IN SELECT year_month, date_start, date_end FROM fc_year_month(i) LOOP
            sql := format(sql_template, schema_, table_, r.year_month, table_,
                          r.date_start, r.date_end, tablespace_);
            EXECUTE sql;              
        END LOOP;  
    END LOOP;

    RETURN table_;

END;$body$ LANGUAGE PLPGSQL;