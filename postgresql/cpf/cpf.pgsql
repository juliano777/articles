CREATE OR REPLACE FUNCTION fc_aux_cpf_last_dig(num text)
RETURNS int2 AS $$

/*
Função auxiliar que retorna um dos últimos dígitos.
Para 9 o múltiplo é 10 e retorna o primeiro dígito.
Para 10 o múltiplo é 11 e retorna o segundo dígito.
*/

DECLARE
    mult int := 0;  -- Múltiplo utilizado conforme a quantidade de algarismos
    s_dig int2 := 0;  -- Soma das múltiplicações de cada algarismo com o múltiplo
    dig int2 := 0;  -- Dígito retornado (primeiro ou segundo)
    

BEGIN
    /*
    Verifica a quantidade de algarismos do número;
    Se não for 9 ou 10 retorna um erro.
    Para 9 o múltiplo é 10 e retorna o primeiro dígito.
    Para 10 o múltiplo é 11 e retorna o segundo dígito.
    */
    IF length(num) = 9 THEN
        mult := 10;
    ELSIF length(num) = 10 THEN 
        mult := 11;
    ELSE	
        RAISE EXCEPTION 'Erro: A quantidade de algarismos deve ser 9 ou 10!';
    END IF;


    /*
    Para cada algarismo somar a múltiplicação do mesmo com o devido múltiplo.
    */
    FOR i IN 1 .. (length(num)) LOOP
        s_dig := s_dig + (substring(num, i, 1)::int2 * mult);
        mult := mult - 1;
    END LOOP;

    dig := (s_dig * 10) % 11;  -- Dígito resultante da operação matemática.

    /*
    Se o resultado da variável dig for 10, mudar para 0 (zero).
    */
    IF dig = 10 THEN
        dig := 0;
    END IF;  

    RETURN dig;

END;$$ LANGUAGE PLPGSQL;


COMMENT ON FUNCTION fc_aux_cpf_last_dig IS
'Função auxiliar que retorna um dos últimos dígitos.
Para 9 o múltiplo é 10 e retorna o primeiro dígito.
Para 10 o múltiplo é 11 e retorna o segundo dígito.';


-- ============================================================================


CREATE OR REPLACE FUNCTION fc_cpf_11_digitos(num text)
RETURNS text AS $$

/*
Retorna o número de CPF com 11 (onze) dígitos.
*/

DECLARE
    d1 int2 := fc_aux_cpf_last_dig(num);  -- Décimo dígito.
    d2 int2 := fc_aux_cpf_last_dig(num||d1::text);  -- Décimo primeiro dígito.
BEGIN
    /* Retorna a concatenação do número com os dois últimos dígitos. */
    RETURN (num||d1::text||d2::text);

END;$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION fc_cpf_11_digitos IS
'Função que recebe um CPF sem os últimos dois dígitos e retorna um de onze';


-- ============================================================================


CREATE OR REPLACE FUNCTION fc_cpf_valida(num text)
RETURNS boolean AS $$

/*
Retorna true se o CPF for válido.
*/

DECLARE
	cpf9 text := substring(num, 1, 9);  -- Nove primeiros dígitos
	d text := substring(num, 10, 11);  -- Os dois últimos dígitos
	
	
    invalidos int8[] := array[  -- Array contendo números de CPF inválidos
                      0,
                      11111111111,
                      22222222222,
                      33333333333,
                      44444444444,
                      55555555555,
                      66666666666,
                      77777777777,
                      88888888888,
                      99999999999];

    
BEGIN
	/* Validação para rejeitar CPF inválido */
	IF array[num::int8] <@ invalidos -- CPF passado é elemento do vetor de
                                         -- números inválidos.
	    OR length(num) != 11  -- Não contém 11 dígitos.
	    OR lpad(fc_cpf_11_digitos(cpf9)::text, 11, '0')
                != (cpf9||d) THEN -- O resultado da função é diferente da 
                                  -- concatenação dos nove com os últimos
                                  -- dois dígitos.		
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;	
    

END;$$ LANGUAGE PLPGSQL;


COMMENT ON FUNCTION fc_cpf_valida IS
'Função para validar um número de CPF';

-- ============================================================================

CREATE OR REPLACE FUNCTION fc_cpf_formata(num text)
RETURNS text AS $$

/*
Retorna o CPF formatado.
*/
    
BEGIN
	IF length(num) = 9 THEN
		num := fc_cpf_11_digitos(num);
	ELSIF length(num) != 11 THEN
		RAISE EXCEPTION 'Erro: A quantidade de algarismos deve ser 9 ou 10!';
	END IF;
	
	RETURN to_char(num::int8, '000"."000"."000-00');
	
END;$$ LANGUAGE PLPGSQL;

-- ============================================================================

CREATE OR REPLACE FUNCTION fc_cpf_gera()
RETURNS text AS $$

/*
Gera um CPF válido.
*/

DECLARE
    cpf9 text := substring(random()::text, 3, 9);
    
BEGIN

    RETURN fc_cpf_11_digitos(cpf9);

	
END;$$ LANGUAGE PLPGSQL;

-- ============================================================================


