/* Test table creation */;

CREATE TABLE tb_target (id int4 PRIMARY KEY, balance int4);

CREATE TABLE tb_source (id serial PRIMARY KEY, sid int4, delta int4);


/* Populate the tables */;

INSERT INTO tb_target (id, balance)
    VALUES (1, 0), (2, 10), (3, -5);

INSERT INTO tb_source (sid, delta)
    VALUES (1, 10), (2, 0), (3, 15), (4, 70), (1, 5);



/* Check the content of the tables */;

TABLE tb_target;

/*
 id | balance 
-----+---------
   1 |       0
   2 |      10
   3 |      -5
*/


TABLE tb_source;

/*
 id | sid | delta 
----+-----+-------
  1 |   1 |    10
  2 |   2 |     0
  3 |   3 |    15
  4 |   4 |    70
  5 |   1 |     5
*/



/* Merge data */;

MERGE INTO tb_target AS t
    USING tb_source AS s
        ON t.id = s.sid
    WHEN MATCHED AND t.balance > s.delta THEN
        UPDATE SET balance = t.balance - s.delta
    WHEN MATCHED THEN DELETE
    WHEN NOT MATCHED AND s.delta > 0 THEN
       INSERT VALUES (s.sid, s.delta)
    WHEN NOT MATCHED THEN DO NOTHING;



/* sddçsçdlsçdlsldç */

SELECT * FROM tb_source WHERE sid = 1;



/* fdçdlfçdflç */

DELETE FROM tb_source WHERE id = 5;

MERGE INTO tb_target AS t USING tb_source AS s
   ON t.id = s.sid
   WHEN MATCHED AND t.balance > s.delta THEN
       UPDATE SET balance = t.balance - s.delta
   WHEN MATCHED THEN DELETE
   WHEN NOT MATCHED AND s.delta > 0 THEN
       INSERT VALUES (s.sid, s.delta)
   WHEN NOT MATCHED THEN DO NOTHING;
