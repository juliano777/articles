-- Como Eliminar Linhas Duplicadas no PostgreSQL

/*

*/;


-- Coluna de Sistema ctid

-- https://www.postgresql.org/docs/current/ddl-system-columns.html

/*
Toda tabela tem algumas colunas implicitamente definidas pelo sistema, cujos nomes são reservados.
Atualmente as colunas de sistema são: tableoid, xmin, cmin, xmax, cmax e ctid. Cada uma tem metadados da
tabela à qual pertencem.
A coluna de sistema ctid tem por finalidade armazenar a  versão da localização física da linha. Essa versão
pode mudar caso a linha seja atualizada (UPDATE) ou a tabela passe por um VACUUM FULL.
A coluna ctid é do tipo tid, que significa tuple identifier (row identifier), que é um par (número do bloco, índice de tupla dentro do bloco)
que identificaa localização física da linha dentro da tabela.
*/;

-- https://www.postgresql.org/docs/current/datatype-oid.html


CREATE TABLE tb_teste_ctid (
    col1 int,
    col2 text);


INSERT INTO tb_teste_ctid VALUES 
(1, 'foo'),
(2, 'bar'),
(3, 'baz');

SELECT ctid, * FROM tb_teste_ctid;

/*
 ctid  | col1 | col2 
-------+------+------
 (0,1) |    1 | foo
 (0,2) |    2 | bar
 (0,3) |    3 | baz
*/

UPDATE tb_teste_ctid SET col2 = 'spam' WHERE col1 = 1;


SELECT ctid, * FROM tb_teste_ctid;

/*
 ctid  | col1 | col2 
-------+------+------
 (0,2) |    2 | bar
 (0,3) |    3 | baz
 (0,4) |    1 | spam
*/;

VACUUM FULL tb_teste_ctid;

UPDATE tb_teste_ctid SET col2 = 'eggs' WHERE col1 = 1 RETURNING ctid;

/*
 ctid  
-------
 (0,4)
 */


 SELECT ctid, * FROM tb_teste_ctid;

/*
 ctid  | col1 | col2 
-------+------+------
 (0,2) |    2 | bar
 (0,3) |    3 | baz
 (0,4) |    1 | spam
*/;





CREATE TABLE tb_foo(
    id_ int,  --This field will be the primary key in the future!
    letter char(1)
);

INSERT INTO tb_foo (id_, letter) SELECT generate_series(1, 10), 'a';

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


INSERT INTO tb_foo (id_, letter) SELECT generate_series(1, 3), 'b';


ALTER TABLE tb_foo ADD CONSTRAINT tb_foo_pkey PRIMARY KEY (id_);

/*
ERROR:  could not create unique index "tb_foo_pkey"
DETAIL:  Key (id_)=(3) is duplicated.
*/;


WITH t AS (
SELECT
    id_,
    count(id_) OVER (PARTITION BY id_) AS count_id,
    ctid,
    max(ctid) OVER (PARTITION BY id_) AS max_ctid
    
    FROM tb_foo
)

SELECT t.id_, t.max_ctid FROM t WHERE t.count_id > 1 GROUP by id_, max_ctid;

/*
 id_ | max_ctid 
-----+----------
   3 | (0,13)
   1 | (0,11)
   2 | (0,12)
*/;



WITH

t1 AS (
SELECT
    id_,
    count(id_) OVER (PARTITION BY id_) AS count_id,
    ctid,
    max(ctid) OVER (PARTITION BY id_) AS max_ctid
    
    FROM tb_foo
),

t2 AS (
SELECT t1.id_, t1.max_ctid
    FROM t1
    WHERE t1.count_id > 1
    GROUP by t1.id_, t1.max_ctid)

DELETE
    FROM tb_foo AS f
    USING t2
    WHERE 
        f.id_ = t2.id_ AND
        f.ctid < t2.max_ctid;



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