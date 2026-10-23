
-- Function: public.json_deleteVD(json, varchar)

-- DROP FUNCTION public.json_deleteVD(json, varchar);

CREATE OR REPLACE FUNCTION public.json_deleteVD(
	i_json json,
	i_clave varchar)
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
				select json_deleteVD('{"idTipoTramiteDetallado" : 483, "tipoLicencia" : "No especificado", "idTipoLicencia" : 0, "categorias" : null, "jajaja" : 1}','"idTipoTramiteDetallado"')
				select json_deleteVD('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null }]','"jajaja"')

	*/
	if i_json::varchar like '{%' and i_json::varchar like '%}' then


			i_clave = trim(i_clave, '"');

			for d_record in (

				with json_delete_tmp as (

					select
						key,
						value
					from
						json_each(i_json)
					where
						key <> i_clave

				)
					select
						*
					from
						json_delete_tmp

			)
			loop

				string = string ||'"'|| d_record.key ||'"'||','|| d_record.value||',';

			end loop;

				string = replace(RTRIM(string, ','), '"', '''');

			execute 'select json_build_object('||string||')' into i_json;

		else
			return json_build_object('ERROR','Solo se puede eliminar un elemento a un objecto');
		end if;

	RETURN i_json;
END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION public.json_deleteVD(json, varchar)
	OWNER TO postgres;
COMMENT ON FUNCTION public.json_deleteVD(json, varchar) IS 'json_deleteVD';
