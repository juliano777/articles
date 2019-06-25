-- Audit / Log Tables

/*
    Audit / log tables are regular tables whose differential is their purpose, which is to track transactions from other table.
    Its records should never be updated, the only accepted DML write operation is INSERT.
    It is highly recommended to partition an audit table, because when a certain range of records is no longer needed, usually older data, you just have to delete the partitions (DROP), which is a much more elegant and efficient solution than using DELETE.
    Audit tables allow us to know who did something, when did, check for wrong updates, maintain history and among other things also do analytic queries.
    Recordings in audit tables are triggered by triggers, which are triggered by INSERT, UPDATE, and DELETE events.
*/



-- Table Partitioning

/*
     With PostgreSQL 10 was added the declarative partitioning feature, which came to make things much easier.
     It is strongly recommended to partition large tables so that it is easier to maintain, avoid locks and there are also performance gains.
     In a partitioned table, a partition is a subtable that contains data given an established criteria, such as a date range, for example.
     For audit tables partitioning is a good practice, because if a particular data range or other partitioning criteria are no longer needed, simply remove partitions with DROP, a much less costly and clean operation for a database than DELETE.
*/





-- Database creation for the tests:

CREATE DATABASE db_audit;



-- Connect to the database (via psql):

\c db_audit

-- Table creations ==========================================================;

-- Original table of users (audited table)

CREATE TABLE tb_user(
    username VARCHAR(50) PRIMARY KEY,
    password VARCHAR(12) NOT NULL,
    active boolean DEFAULT TRUE);



-- Schema for the partitions;

CREATE SCHEMA sc_audit_partitions;


-- Schema for audit objects;

CREATE SCHEMA sc_audit;


-- Audit table of users (partitioned);

CREATE TABLE sc_audit.tb_user_audit(
    username VARCHAR(50) NOT NULL,
    password VARCHAR(12) NOT NULL,
    active boolean NOT NULL,
    modif_ts TIMESTAMP WITH TIME ZONE NOT NULL,  -- Modification date
    modif_user VARCHAR(50) NOT NULL,  -- User who made the change
    op CHAR(1) NOT NULL)   -- Operation (INSERT: I, UPDATE: U, DELETE: D)
    PARTITION BY RANGE (modif_ts);



-- ============================ Functions to partitions =====================;

-- fc_aux_year_month --------------------------------------------------------;

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

*/

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

CREATE OR REPLACE FUNCTION fc_create_partition_range(
    year_start int,
    year_end int,
    table_ text,
    part_ text,
    tablespace_ text DEFAULT 'pg_default'
    )
RETURNS TEXT AS $body$

/* 
Function - fc_create_partition_range

This function creates a range of partitions given a a year of start and year
of end.
 

*/

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


SELECT fc_create_partition_range(2019, 2021,
                                 'sc_audit.tb_user_audit',
                                 'sc_audit_partitions.tb_user_audit');



-- Default partition (catch all table):

CREATE TABLE sc_audit_partitions.tb_user_audit_default
    PARTITION OF sc_audit.tb_user_audit DEFAULT;

-- fc_tg_audit_user ---------------------------------------------------------;


CREATE OR REPLACE FUNCTION sc_audit.fc_tg_audit_user()
RETURNS TRIGGER AS $body$

DECLARE
    op CHAR(1) := left(TG_OP, 1);
    username_ TEXT;
    password_ TEXT;
    active_ boolean;


    sql_template TEXT := $$
        INSERT INTO sc_audit.tb_user_audit (
            username,
            password,
            active,
            modif_ts,
            modif_user,
            op)
            VALUES 
            ('%s', '%s', '%s', now(), 'foo', '%s');        
        $$;

    sql TEXT;

BEGIN
    IF (op IN ('I', 'U')) THEN
        username_ := NEW.username;
        password_ := NEW.password;
        active_ := NEW.active;

    ELSIF (op = 'D') THEN
        username_ := OLD.username;
        password_ := OLD.password;
        active_ := OLD.active;
    END IF;   

        sql := format(sql_template, username_, password_, active_, op);
        EXECUTE sql;

    RETURN NULL;

END;$body$ LANGUAGE PLPGSQL;


CREATE TRIGGER tg_audit_user
    AFTER INSERT OR UPDATE OR DELETE ON tb_user
    FOR EACH ROW EXECUTE PROCEDURE sc_audit.fc_tg_audit_user();



INSERT INTO tb_user (username, password) VALUES 
    ('admin', '123'),
    ('newuser', '456'),
    ('olduser', '789');

TABLE tb_user;

/*
 username | password | active 
----------+----------+--------
 admin    | 123      | t
 newuser  | 456      | t
 olduser  | 789      | t
*/



TABLE sc_audit.tb_user_audit ;

/*
 username | password | active |           modif_ts            | modif_user | op 
----------+----------+--------+-------------------------------+------------+----
 admin    | 123      | t      | 2019-06-24 15:54:43.544931+00 | foo        | I
 newuser  | 456      | t      | 2019-06-24 15:54:43.544931+00 | foo        | I
 olduser  | 789      | t      | 2019-06-24 15:54:43.544931+00 | foo        | I
*/




TABLE sc_audit.tb_user_audit ;

/*
 username | password | active |           modif_ts            | modif_user | op 
----------+----------+--------+-------------------------------+------------+----
 admin    | 123      | t      | 2019-06-24 15:54:43.544931+00 | foo        | I
 newuser  | 456      | t      | 2019-06-24 15:54:43.544931+00 | foo        | I
 olduser  | 789      | t      | 2019-06-24 15:54:43.544931+00 | foo        | I
 admin    | 1221     | t      | 2019-06-24 15:56:48.979498+00 | foo        | U
*/



DELETE FROM tb_user WHERE username = 'olduser';

TABLE sc_audit.tb_user_audit;

/*
 username | password | active |           modif_ts            | modif_user | op 
----------+----------+--------+-------------------------------+------------+----
 admin    | 123      | t      | 2019-06-24 18:30:24.799481+00 | foo        | I
 newuser  | 456      | t      | 2019-06-24 18:30:24.799481+00 | foo        | I
 olduser  | 789      | t      | 2019-06-24 18:30:24.799481+00 | foo        | I
 olduser  | 789      | t      | 2019-06-24 18:30:41.693387+00 | foo        | D
*/



UPDATE tb_user SET password = 'admin' WHERE username = 'admin';

/*
 username | password | active |           modif_ts            | modif_user | op 
----------+----------+--------+-------------------------------+------------+----
 admin    | 123      | t      | 2019-06-24 18:30:24.799481+00 | foo        | I
 newuser  | 456      | t      | 2019-06-24 18:30:24.799481+00 | foo        | I
 olduser  | 789      | t      | 2019-06-24 18:30:24.799481+00 | foo        | I
 olduser  | 789      | t      | 2019-06-24 18:30:41.693387+00 | foo        | D
 admin    | admin    | t      | 2019-06-24 18:31:37.00592+00  | foo        | U
*/



TABLE tb_user;

/*
 username | password | active 
----------+----------+--------
 newuser  | 456      | t
 admin    | admin    | t
*/

