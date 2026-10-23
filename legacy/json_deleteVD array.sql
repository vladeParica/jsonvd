
-- Function: public.json_deleteVD(json, varchar, integer)

-- DROP FUNCTION public.json_deleteVD(json, varchar, integer);

CREATE OR REPLACE FUNCTION public.json_deleteVD(
	i_json json,
	i_clave varchar,
	i_position integer)
RETURNS json AS
$BODY$
DECLARE
	d_record record;
	string varchar = '';
	d_json json;
	d_keys record;
BEGIN
	/*
	Hecho por: Vlade Párica
	Fecha:
	Resumen:

	Para probarlo:

				select json_deleteVD('[{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null, "jajaja": 1 },{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null, "jajaja": 1 }]','categorias',1)

				select json_deleteVD('{"idTipoTramiteDetallado": 483, "tipoLicencia": "No especificado", "idTipoLicencia": 0, "categorias": null, "jajaja": 1 }','categorias',1)


	*/
	if i_json::varchar like '[%' and i_json::varchar like '%]'  then


		for d_record in (

			with json_delete_tmp as (

				select
					value,
					position-1 as position
				from
					jsonb_array_elements(i_json::jsonb) with ordinality arr(value, position)
			)
				select
					*
				from
					json_delete_tmp
		)
		loop

			if d_record.position = i_position then

				d_json = json_deleteVD(d_record.value::json,i_clave);

				with validation_tmp as (

					select json_object_keys(d_json) as value
				)
					select
						* into d_keys
					from
						validation_tmp
					where
						value <> 'ERROR'
				;

				if d_keys is null then
					return json_build_object('ERROR','Solo se puede eliminar un elemento a un objecto');
				end if;


				string = string || d_json::varchar || ',';

			else
				string = string || d_record.value || ',';
			end if;

		end loop;

		string = rtrim(string, ',');
		i_json = '['||string||']';

	else
		return '['||json_build_object('ERROR','solo se puede eliminar con un array indicando la clave y posicion')||']';
	end if;

	RETURN i_json;
END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION public.json_deleteVD(json, varchar, integer)
	OWNER TO postgres;
COMMENT ON FUNCTION public.json_deleteVD(json, varchar, integer) IS 'json_deleteVD';
