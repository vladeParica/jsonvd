-- Function: typeof_vd(text)

-- DROP FUNCTION typeof_vd(text);

CREATE OR REPLACE FUNCTION typeof_vd(i_value text)
  RETURNS character varying AS
$BODY$
DECLARE
	d_new_json json;
	string text default '';
	d_record record;
	d_constructor text;
	d_aux text;
BEGIN
	/*
	Hecho por: Dey
	Fecha: 08-06-2018
	Resumen: Agrega un valor a un objeto

	Para probarlo:
		select typeof_vd('1')
		select typeof_vd('a')
		select typeof_vd('{}')
		select typeof_vd('[]')
		select typeof_vd('true')
		select typeof_vd('null')
	*/


		BEGIN
			IF (lower(i_value) = 'null') THEN
				RETURN 'NULL';
			END IF;
			EXCEPTION WHEN others THEN NULL; --RAISE INFO 'NOT NULL';
		END;

		BEGIN
			IF (i_value::boolean in ('true','false') and i_value not in ('1','0')) THEN
				RETURN 'boolean';
			END IF;
			EXCEPTION WHEN others THEN NULL; --RAISE INFO 'NOT BOOLEAN';
		END;

		BEGIN
			IF (i_value::int) IS NOT NULL THEN
				RETURN 'int';
			END IF;
			EXCEPTION WHEN others THEN NULL ; -- RAISE INFO 'NOT INTEGER';
		END;

		BEGIN
			IF (i_value::date) IS NOT NULL THEN
				RETURN 'date';
			END IF;
			EXCEPTION WHEN others THEN NULL ; -- RAISE INFO 'NOT DATE';
		END;

		BEGIN
			IF (json_typeof(i_value::json) = 'object' or json_typeof(i_value::json) = 'array') THEN
				RETURN 'json';

			END IF;
			EXCEPTION WHEN others THEN NULL ;-- RAISE INFO 'NOT OBJECT';
		END;

		BEGIN
			IF (i_value::varchar) IS NOT NULL THEN
				RETURN 'text';

			END IF;
			EXCEPTION WHEN others THEN NULL ; -- RAISE INFO 'NOT VACHAR';
		END;

	RETURN 'Ingrese un tipo de dato valido';
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION typeof_vd(text)
  OWNER TO postgres;
COMMENT ON FUNCTION typeof_vd(text) IS 'typeof_vd';
