
-- Function: public.json_pushVD(json, varchar, varchar)

-- DROP FUNCTION public.json_pushVD(json, varchar, varchar);

CREATE OR REPLACE FUNCTION public.json_pushVD(
	i_json json,
	i_clave varchar,
	i_value varchar)
RETURNS json AS
$BODY$
DECLARE
	d_record record;
	string varchar = '';
	string2 varchar = '';
	d_tipo_json varchar default 'to_json';
BEGIN
	/*
	Hecho por: Vlade Párica
	Fecha:
	Resumen:

	Para probarlo:
				select json_pushVD('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','"jajaja"','5')
				select json_pushVD('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','"jajaja"','[{"hola":"hola","otrcosa":0,"otracosa2":true}]')
				select json_pushVD('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','"jajaja"','hola')
	*/

	IF (i_value::varchar like '{%' and i_value::varchar like '%}' --and i_value::varchar != '{}'
		) THEN
	raise notice 'Entre';

		i_clave = trim(i_clave, '"');
		i_value = trim(i_value, '"');

		for d_record in select * from json_each(i_json)
			loop
				IF (d_record.value::text like '"%') THEN
					string = string || '''' || d_record.value::text|| '''' || ' ' ||'"'|| d_record.key ||'"'||', ';
				ELSE
					string = string || d_record.value::text || ' ' ||'"'|| d_record.key ||'"'||', ';
				END IF;
			end loop;

		for d_record in select * from json_each(i_value::json)
			loop
				string2 = string2 ||'"'|| d_record.key ||'"'||',' || d_record.value::text|| ',';
			end loop;
			string2 = replace(RTRIM(string2, ','), '"', '''');
			raise notice 'Segundo jsonv2 %', string2;
		IF ( json_typeof(i_value::json) = 'array' ) THEN
			execute 'select json_agg(a.*) from ( select ' || string || '(array_agg(b.*) as ' || i_clave || ' from ( select ' || string2 || ')b )' || ' )a' into i_json;
		ELSE
			execute 'select to_json(a.*) from ( select ' || string || 'json_build_object(' || string2 || ') as' || i_clave || ' )a' into i_json;
		END IF;

			i_json := replace(i_json::text,(CHR(92)||'"'),'');

	elsif i_json::varchar like '{%' and i_json::varchar like '%}' then

			i_clave = trim(i_clave, '"');
			i_value = trim(i_value, '"');

			for d_record in select * from json_each(i_json)
			loop

				string = string ||'"'|| d_record.key ||'"'||','|| d_record.value||',';

			end loop;

				string = string ||'"'|| i_clave ||'"'||','||'"'||i_value||'"'||',';
				string = replace(RTRIM(string, ','), '"', '''');

			execute 'select json_build_object('||string||')' into i_json;
		else
			return json_build_object('ERROR','Solo se puede agregar un elemento a un objecto');
		end if;

	RETURN i_json;
END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION public.json_pushVD(json, varchar, varchar)
	OWNER TO postgres;
COMMENT ON FUNCTION public.json_pushVD(json, varchar, varchar) IS 'json_pushVD';
