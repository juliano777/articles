-- PostgreSQL - How to Eliminate Repeated Values

/*
It's possible that in a table, some field that has repeated values is necessary to leave it as unique.
And how to proceed with repeated values without eliminating them all?
Would it be possible leave only the most current?
*/;


-- ctid System Column

-- https://www.postgresql.org/docs/current/ddl-system-columns.html

/*
Every table has some columns implicitly defined by the system, whose names are reserved.
Currently the system columns are: tableoid, xmin, cmin, xmax, cmax and ctid. Each one has metadata from table which they belong.
The ctid system column is intended to store the version of the physical location of the row. This version can change if the row
is updated (UPDATE) oor the table goes through a VACUUM FULL.
The data type of ctid is tid, that means tuple identifier (or row identifier), which is a pair (block number, tuple index within the block)
that identifies the physical location of the row within the table.
This column always has its unique value in the table, so when there are rows with repeated values it can be used as criterion for their elimination.
*/;

-- https://www.postgresql.org/docs/current/datatype-oid.html



-- Test table creation:

CREATE TABLE tb_test_ctid (
    col1 int,
    col2 text);




-- Insert some data:    

INSERT INTO tb_test_ctid VALUES 
(1, 'foo'),
(2, 'bar'),
(3, 'baz');


-- Check current rows:

SELECT ctid, * FROM tb_test_ctid;

/*
 ctid  | col1 | col2 
-------+------+------
 (0,1) |    1 | foo
 (0,2) |    2 | bar
 (0,3) |    3 | baz
*/



-- Update a row:

UPDATE tb_test_ctid SET col2 = 'spam' WHERE col1 = 1;


-- Check the table again:


SELECT ctid, * FROM tb_test_ctid;

/*
 ctid  | col1 | col2 
-------+------+------
 (0,2) |    2 | bar
 (0,3) |    3 | baz
 (0,4) |    1 | spam
*/;

-- We can notice that the updated row had its ctid changed as well...



-- VACUUM FULL test:

VACUUM FULL tb_test_ctid;



-- Update the same row again using the RETURNING clause:

UPDATE tb_test_ctid
    SET col2 = 'eggs'
    WHERE col1 = 1
    RETURNING ctid;

/*
 ctid  
-------
 (0,4)
*/



-- Check the table again:

 SELECT ctid, * FROM tb_test_ctid;

/*
 ctid  | col1 | col2 
-------+------+------
 (0,2) |    2 | bar
 (0,3) |    3 | baz
 (0,4) |    1 | spam
*/



-- Eliminating Repeated Values with ctid

/*
Imagine a table that has repeated values in a field and that same field is decided to make it unique later.
Remember that a PRIMARY KEY field is also unique.
OK, it was decided that the repeated values in that field will be deleted.
It's now necessary to establish a criterion to decide among these repeated values which will remain.
In the following case, the criterion is the most current line, that is, the one with the highest ctid value.
*/;



-- New test table creation:

CREATE TABLE tb_foo(
    id_ int,  --This field will be the primary key in the future!
    letter char(1)
);



-- Insert 10 records:

INSERT INTO tb_foo (id_, letter) SELECT generate_series(1, 10), 'a';



-- Check the table:

SELECT id_, letter FROM tb_foo;

/*
 id_ | letter 
-----+--------
   1 | a
   2 | a
   3 | a
   4 | a
   5 | a
   6 | a
   7 | a
   8 | a
   9 | a
  10 | a
*/;



-- Insert 3 more records:

INSERT INTO tb_foo (id_, letter) SELECT generate_series(1, 3), 'b';


-- Check repeated values:

SELECT id_, letter FROM tb_foo WHERE id_ <= 3;

/*
 id_ | letter  
-----+--------
   1 | a
   2 | a
   3 | a
   1 | b
   2 | b
   3 | b
*/

-- There are repeated values in the table's id_ field...



--- Attempt to make the id_ field a primary key:

ALTER TABLE tb_foo ADD CONSTRAINT tb_foo_pkey PRIMARY KEY (id_);

/*
ERROR:  could not create unique index "tb_foo_pkey"
DETAIL:  Key (id_)=(3) is duplicated.
*/;



-- Using CTE and window functions, find out which repeated values will be kept:

WITH t AS (
SELECT
    id_,
    count(id_) OVER (PARTITION BY id_) AS count_id,  -- Count
    ctid,
    max(ctid) OVER (PARTITION BY id_) AS max_ctid  -- Most current ctid
    
    FROM tb_foo
)

SELECT
    t.id_,
    t.max_ctid
    FROM t
    WHERE t.count_id > 1  -- Filters which values repeat
    GROUP by id_, max_ctid;

/*
 id_ | max_ctid 
-----+----------
   3 | (0,13)
   1 | (0,11)
   2 | (0,12)
*/;




-- Leaving the table with unique values for the id_ field, removing the older rows:

WITH

t1 AS (
SELECT
    id_,
    count(id_) OVER (PARTITION BY id_) AS count_id,
    ctid,
    max(ctid) OVER (PARTITION BY id_) AS max_ctid
    
    FROM tb_foo
),

t2 AS (  -- Virtual table that filters repeated values that will remain
SELECT t1.id_, t1.max_ctid
    FROM t1
    WHERE t1.count_id > 1
    GROUP by t1.id_, t1.max_ctid)

DELETE  -- DELETE with JOIN 
    FROM tb_foo AS f
    USING t2
    WHERE 
        f.id_ = t2.id_ AND  -- tb_foo has id_ equal to t2 (repeated values)
        f.ctid < t2.max_ctid;  -- ctid is less than the maximum (most current)



-- Checking table values without duplicated values for id_:

SELECT id_, letter FROM tb_foo;

/*
 id_ | letter 
-----+--------
   4 | a
   5 | a
   6 | a
   7 | a
   8 | a
   9 | a
  10 | a
   1 | b
   2 | b
   3 | b        
*/;



-- You can now change the table to leave the id_ field as PRIMARY KEY:

ALTER TABLE tb_foo ADD CONSTRAINT tb_foo_pkey PRIMARY KEY (id_);