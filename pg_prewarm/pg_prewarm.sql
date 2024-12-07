/*
mkdir -m 0700 /prewarm

chown postgres: /prewarm

vim ${PGDATA}/postgresql.conf

pg_prewarm.autoprewarm = on
pg_prewarm.autoprewarm_interval = 300s


*/


CREATE DATABASE db_prewarm TABLESPACE ts_prewarm;

\c db_prewarm

CREATE SCHEMA sc_prewarm;

CREATE EXTENSION pg_prewarm WITH SCHEMA sc_prewarm;

CREATE OR REPLACE FUNCTION fc_array_string (num_chars int)
RETURNS TEXT AS $$
BEGIN
    RETURN array_to_string(
        ARRAY(
              SELECT chr((48 + round(random() * 59)) :: integer)
              FROM generate_series(1, num_chars)
              ), '');
END; $$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION fc_random_between (int, int)
RETURNS INT AS $$
BEGIN                                                          
     RETURN floor(random() * ($2 - $1 + 1) + $1)::int;
END; $$ LANGUAGE PLPGSQL;


CREATE TABLE tb_foo(
    id_ serial primary key,
    f_int int,
    f_text text);
    
WITH t AS (
    SELECT
        generate_series(1, 50000000) AS i,
        fc_random_between(1, 1500) AS f_int,
        fc_array_string(fc_random_between(1, 50)) AS f_text
)
INSERT INTO tb_foo(f_int, f_text) SELECT f_int, f_text FROM t;


EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
    FROM tb_foo
    WHERE f_int = 414;
    
/*
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=660860.91..660860.92 rows=1 width=8) (actual time=22226.888..22228.424 rows=1 loops=1)
   Buffers: shared hit=32 read=405880 dirtied=349306 written=1598
   ->  Gather  (cost=660860.69..660860.90 rows=2 width=8) (actual time=22226.739..22228.415 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=32 read=405880 dirtied=349306 written=1598
         ->  Partial Aggregate  (cost=659860.69..659860.70 rows=1 width=8) (actual time=22221.826..22221.827 rows=1 loops=3)
               Buffers: shared hit=32 read=405880 dirtied=349306 written=1598
               ->  Parallel Seq Scan on tb_foo  (cost=0.00..659607.00 rows=101478 width=0) (actual time=7.914..22216.458 rows=11091 loops=3)
                     Filter: (f_int = 414)
                     Rows Removed by Filter: 16655576
                     Buffers: shared hit=32 read=405880 dirtied=349306 written=1598
 Planning:
   Buffers: shared hit=69
 Planning Time: 2.021 ms
 Execution Time: 22228.513 ms
*/


CREATE TABLE tb_bar (                                                                 
    id_ serial primary key,
    f_int integer,
    f_text text);
    
INSERT INTO tb_bar (f_int, f_text)
    SELECT f_int, f_text FROM tb_foo;
        
        
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
    FROM tb_bar
    WHERE f_int = 414;
    
/*
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=660860.91..660860.92 rows=1 width=8) (actual time=20324.276..20325.750 rows=1 loops=1)
   Buffers: shared hit=71 read=405841 dirtied=295563 written=1503
   ->  Gather  (cost=660860.69..660860.90 rows=2 width=8) (actual time=20324.132..20325.739 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=71 read=405841 dirtied=295563 written=1503
         ->  Partial Aggregate  (cost=659860.69..659860.70 rows=1 width=8) (actual time=20315.725..20315.726 rows=1 loops=3)
               Buffers: shared hit=71 read=405841 dirtied=295563 written=1503
               ->  Parallel Seq Scan on tb_bar  (cost=0.00..659607.00 rows=101478 width=0) (actual time=8.955..20310.410 rows=11091 loops=3)
                     Filter: (f_int = 414)
                     Rows Removed by Filter: 16655576
                     Buffers: shared hit=71 read=405841 dirtied=295563 written=1503
 Planning:
   Buffers: shared hit=52 read=17
 Planning Time: 18.896 ms
 Execution Time: 20325.866 ms
*/        

        
SELECT sc_prewarm.pg_prewarm('tb_foo');

SELECT sc_prewarm.pg_prewarm('tb_bar');

