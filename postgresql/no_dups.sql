CREATE TABLE tb_foo(
    id int,  --This field will be the primary key in the future!
    letter char(1)
);

INSERT INTO tb_foo (id, letter) SELECT generate_series(1, 10), 'a';

TABLE tb_foo;

/*
 id | letter 
----+--------
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


INSERT INTO tb_foo (id, letter) SELECT generate_series(1, 3), 'b';


ALTER TABLE tb_foo ADD CONSTRAINT tb_foo_pkey PRIMARY KEY (id);

/*
ERROR:  could not create unique index "tb_foo_pkey"
DETAIL:  Key (id)=(3) is duplicated.
*/;


WITH t AS (
SELECT
    id,
    count(id) OVER (PARTITION BY id) AS count_id,
    ctid,
    max(ctid) OVER (PARTITION BY id) AS max_ctid
    
    FROM tb_foo
)

SELECT t.id, t.max_ctid FROM t WHERE t.count_id > 1 GROUP by id, max_ctid;



WITH

t1 AS (
SELECT
    id,
    count(id) OVER (PARTITION BY id) AS count_id,
    ctid,
    max(ctid) OVER (PARTITION BY id) AS max_ctid
    
    FROM tb_foo
),

t2 AS (
SELECT t1.id, t1.max_ctid
    FROM t1
    WHERE t1.count_id > 1
    GROUP by t1.id, t1.max_ctid)

DELETE
    FROM tb_foo AS f
    USING t2
    WHERE 
        f.id = t2.id AND
        f.ctid < t2.max_ctid;
