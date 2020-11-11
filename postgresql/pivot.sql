-- https://www.vertabelo.com/blog/creating-pivot-tables-in-postgresql-using-the-crosstab-function/

/*
How the Crosstab Function Works

The crosstab function receives an SQL SELECT command as a parameter, which must be compliant with the following restrictions:

    The SELECT must return 3 columns.
    The first column in the SELECT will be the identifier of every row in the pivot table or final result. In our example, this is the student’s name. Notice how students’ names (John Smith and Peter Gabriel) appear in the first column.
    The second column in the SELECT represents the categories in the pivot table. In our example, these categories are the school subjects. It is important to note that the values of this column will expand into many columns in the pivot table. If the second column returns five different values (geography, history, and so on) the pivot table will have five columns.
    The third column in the SELECT represents the value to be assigned to each cell of the pivot table. These are the evaluation results in our example.

If we think of our pivot table as a two-dimensional array, then the first SELECT column is the first array dimension, the second SELECT column is the second dimension, and the third is the array element value.like grid [first_column_value, second_column_value] = third_column_value.
*/

CREATE EXTENSION tablefunc;


CREATE TABLE tb_gastos_viagem (
    id_ int GENERATED ALWAYS AS IDENTITY,
    dt timestamp,
    funcionario varchar(150),
    tipo varchar(20),
    valor numeric(7, 2));
    
    
COPY tb_gastos_viagem(funcionario, tipo, valor, dt) FROM STDIN DELIMITER ';';
Esmerivaldo Antunes;passagens;100;2017-07-20
Esmerivaldo Antunes;hospedagem;1050.75;2017-07-20
Esmerivaldo Antunes;alimentacao;40;2017-07-21
Esmerivaldo Antunes;transporte;30;2017-07-21
Esmerivaldo Antunes;alimentacao;30;2017-07-21
Esmerivaldo Antunes;transporte;70;2017-07-22
Averbina Santos;passagens;30;2017-08-01
Averbina Santos;transporte;30;2017-08-01
Averbina Santos;hospedagem;700;2017-08-01
Averbina Santos;alimentacao;30;2017-08-01
Averbina Santos;alimentacao;25;2017-08-01
Berilia Caetano;passagens;150;2017-09-01
Berilia Caetano;transporte;15;2017-09-01
Berilia Caetano;alimentacao;30;2017-09-01
Berilia Caetano;hospedagem;700;2017-09-01
Berilia Caetano;alimentacao;30;2017-09-01
Berilia Caetano;alimentacao;25;2017-09-01


SELECT DISTINCT tipo FROM tb_gastos_viagem ORDER BY tipo;

/*
    tipo     
-------------
 alimentacao
 hospedagem
 passagens
 transporte
*/



SELECT
    funcionario,
    tipo,
    sum(valor) AS valor
    FROM tb_gastos_viagem
    GROUP BY funcionario, tipo
    ORDER BY funcionario;

/*
     funcionario     |    tipo     |  valor  
---------------------+-------------+---------
 Averbina Santos     | alimentacao |   55.00
 Averbina Santos     | hospedagem  |  700.00
 Averbina Santos     | passagens   |   30.00
 Averbina Santos     | transporte  |   30.00
 Berilia Caetano     | alimentacao |   85.00
 Berilia Caetano     | hospedagem  |  700.00
 Berilia Caetano     | passagens   |  150.00
 Berilia Caetano     | transporte  |   15.00
 Esmerivaldo Antunes | alimentacao |   70.00
 Esmerivaldo Antunes | hospedagem  | 1050.75
 Esmerivaldo Antunes | passagens   |  100.00
 Esmerivaldo Antunes | transporte  |  100.00
 */


SELECT * FROM crosstab($$
    SELECT
    funcionario,
    tipo,
    sum(valor) AS valor
    FROM tb_gastos_viagem
    GROUP BY funcionario, tipo
    ORDER BY funcionario
    $$) AS sumario(
                    funcionario varchar(150),
                    alimentacao numeric(7, 2),
                    hospedagem numeric(7, 2),
                    passagens numeric(7, 2),
                    transporte numeric(7, 2));
                    
/*
     funcionario     | alimentacao | hospedagem | passagens | transporte 
---------------------+-------------+------------+-----------+------------
 Averbina Santos     |       55.00 |     700.00 |     30.00 |      30.00
 Berilia Caetano     |       85.00 |     700.00 |    150.00 |      15.00
 Esmerivaldo Antunes |       70.00 |    1050.75 |    100.00 |     100.00
*/                    
                    
                    
                    
                   
                    
    
    
    
    
    
    
    
    
     
        
        
        


