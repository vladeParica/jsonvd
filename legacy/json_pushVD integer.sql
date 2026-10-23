
-- Function: public.json_pushVD(json, varchar, integer)

-- DROP FUNCTION public.json_pushVD(json, varchar, integer);

CREATE OR REPLACE FUNCTION public.json_pushVD(
	i_json json,
	i_clave varchar,
	i_value integer)
RETURNS json AS
$BODY$
DECLARE
	d_record record;
	string varchar = '';
BEGIN
	/*
	Hecho por: Vlade Párica
	Fecha:
	Resumen:

	Para probarlo:
				select json_pushVD('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }','"jajaja"', 1)
				select json_pushVD('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','"jajaja"',1)

	*/
	if i_json::varchar like '{%' and i_json::varchar like '%}' then

			i_clave = trim(i_clave, '"');

			for d_record in select * from json_each(i_json)
			loop

				string = string ||'"'|| d_record.key ||'"'||','|| d_record.value||',';

			end loop;

				string = string ||'"'|| i_clave ||'"'||','||i_value||',';
				string = replace(RTRIM(string, ','), '"', '''');

			execute 'select json_build_object('||string||')' into i_json;
		else
			return json_build_object('ERROR','Solo se puede agregar un elemento a un objecto');
		end if;

	RETURN i_json;
END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION public.json_pushVD(json, varchar, integer)
	OWNER TO postgres;
COMMENT ON FUNCTION public.json_pushVD(json, varchar, integer) IS 'json_pushVD';
