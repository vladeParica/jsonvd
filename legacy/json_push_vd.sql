-- Function: json_push_vd(json, character varying, character varying)

-- DROP FUNCTION json_push_vd(json, character varying, character varying);

CREATE OR REPLACE FUNCTION json_push_vd(
    i_json json,
    i_clave character varying,
    i_value character varying)
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
	Fecha: 09-05-2018
	Resumen: Agrega un valor a un objeto

	Para probarlo:

		-- Object
			select json_push_vd('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','Prueba','ta');
			select json_push_vd('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','Prueba','2018-05-11');
			select json_push_vd('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','Prueba','2');
			select json_push_vd('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','Prueba','true');
			select json_push_vd('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','Prueba','{"hola":"hola","otrcosa":0,"otracosa2":true}');
			select json_push_vd('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','Prueba','[{"hola":"hola","otrcosa":0,"otracosa2":true}]');

		-- Array
			select json_push_vd('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','Prueba','true');
			select json_push_vd('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','Prueba','2018-05-11');
			select json_push_vd('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','Prueba','2');
			select json_push_vd('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','Prueba','true');
			select json_push_vd('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','Prueba','{"hola":"hola","otrcosa":0,"otracosa2":true}');
			select json_push_vd('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','Prueba','[{"hola":"hola","otrcosa":0,"otracosa2":true}]');
	*/

	IF (json_typeof(i_json) = 'object') THEN
		BEGIN
			IF (i_value::boolean) THEN
				-- raise notice 'Soy un boolean';

				FOR d_record IN SELECT * FROM json_each(i_json) LOOP
					string = string || replace(d_record.value::varchar, '"' ,'''') || ' as "' || d_record.key || '" , ';
				END LOOP;

				string = translate(RTRIM(string, ', '),'"','');
				string = string || ',' || i_value::boolean  || ' as ' || i_clave;

				execute 'select to_json(a.*) from ( select ' || string || ')a' into d_new_json;
				RETURN d_new_json;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (i_value::int) IS NOT NULL THEN
				-- raise notice 'Soy un integer';
				FOR d_record IN SELECT * FROM json_each(i_json) LOOP
					string = string || replace(d_record.value::varchar, '"' ,'''') || ' as "' || d_record.key || '" , ';
				END LOOP;

				string = translate(RTRIM(string, ', '),'"','');
				string = string || ',' || i_value::integer  || ' as ' || i_clave;

				execute 'select to_json(a.*) from ( select ' || string || ')a' into d_new_json;

				RETURN d_new_json;
			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (i_value::date) IS NOT NULL THEN
				-- raise notice 'Soy un date';
				FOR d_record IN SELECT * FROM json_each(i_json) LOOP
					string = string || replace(d_record.value::varchar, '"' ,'''') || ' as "' || d_record.key || '" , ';
				END LOOP;

				string = translate(RTRIM(string, ', '),'"','');
				string = string || ',''' || i_value::Date  || ''' as ' || i_clave;

				execute 'select to_json(a.*) from ( select ' || string || ')a' into d_new_json;
				RETURN d_new_json;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (json_typeof(i_value::json) = 'object' or json_typeof(i_value::json) = 'array') THEN
				-- raise notice 'Soy un %',json_typeof(i_value::json);

				FOR d_record IN SELECT * FROM json_each(i_json) LOOP
					IF (d_record.value::varchar like '[%' or d_record.value::varchar like '%]') THEN
						string = string || replace(replace(d_record.value::varchar,'[','''['),']',']''') || ' as "' || d_record.key || '" , ';
					ELSE
						string = string || replace(d_record.value::varchar, '"' ,'''') || ' as "' || d_record.key || '" , ';
						string = translate(string,'"','');
					END IF;
				END LOOP;

				string = RTRIM(string, ', ');
				string = string || ',''' || i_value::json  || '''::json as ' || i_clave;
				execute 'select to_json(a.*) from ( select ' || string || ')a' into d_new_json;
				-- RETURN d_new_json;
				RETURN replace(replace(translate(d_new_json::text,chr(92),''),'"[','['),']"',']');

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (i_value::varchar) IS NOT NULL THEN
				-- raise notice 'Soy un varchar';

				FOR d_record IN SELECT * FROM json_each(i_json) LOOP
					string = string || replace(d_record.value::varchar, '"' ,'''') || ' as "' || d_record.key || '" , ';
				END LOOP;

				string = translate(RTRIM(string, ', '),'"','');
				string = string || ',''' || i_value::text  || ''' as ' || i_clave;

				execute 'select to_json(a.*) from ( select ' || string || ')a' into d_new_json;
				RETURN d_new_json;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

	ELSIF (json_typeof(i_json) = 'array') THEN

		BEGIN
			IF (i_value::boolean) THEN
				-- raise notice 'Soy un boolean';

				execute 'select to_json(a.*) from ( select ' || i_value::boolean || ' as ' || i_clave || ')a' into d_new_json;

				d_aux := i_json::text;
				d_aux := substring(d_aux from 0 for length(d_aux));
				d_aux := d_aux || ',' || d_new_json || ']';

				RETURN d_aux;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (i_value::int) IS NOT NULL THEN
				-- raise notice 'Soy un integer';

				execute 'select to_json(a.*) from ( select ' || i_value::int || ' as ' || i_clave || ')a' into d_new_json;

				d_aux := i_json::text;
				d_aux := substring(d_aux from 0 for length(d_aux));
				d_aux := d_aux || ',' || d_new_json || ']';

				RETURN d_aux;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (i_value::date) IS NOT NULL THEN
				-- raise notice 'Soy un date';

				execute 'select to_json(a.*) from ( select ''' || i_value::date || ''' as ' || i_clave || ')a' into d_new_json;

				d_aux := i_json::text;
				d_aux := substring(d_aux from 0 for length(d_aux));
				d_aux := d_aux || ',' || d_new_json || ']';

				RETURN d_aux;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (json_typeof(i_value::json) = 'object' or json_typeof(i_value::json) = 'array') THEN

				execute 'select to_json(a.*) from ( select ''' || i_value::json || '''::json as ' || i_clave || ')a' into d_new_json;

				d_aux := i_json::text;
				d_aux := substring(d_aux from 0 for length(d_aux));
				d_aux := d_aux || ',' || d_new_json || ']';

				RETURN d_aux::json;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

		BEGIN
			IF (i_value::varchar) IS NOT NULL THEN
				-- raise notice 'Soy un varchar';

				execute 'select to_json(a.*) from ( select ''' || i_value::text || ''' as ' || i_clave || ')a' into d_new_json;

				d_aux := i_json::text;
				d_aux := substring(d_aux from 0 for length(d_aux));
				d_aux := d_aux || ',' || d_new_json || ']';

				RETURN d_aux;

			END IF;
			EXCEPTION WHEN others THEN NULL;
		END;

	END IF;

	RETURN 'Ingrese un tipo de dato valido';
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION json_push_vd(json, character varying, character varying)
  OWNER TO postgres;
