-- Function: sub_return_json_valueVD(json, json, varchar)

-- DROP FUNCTION sub_return_json_valueVD(json, json, varchar);

CREATE OR REPLACE FUNCTION sub_return_json_valueVD(
    i_json json,
    i_position json,
    i_clave varchar)
  RETURNS character varying AS
$BODY$
DECLARE
	d_json record;
	d_long integer;
	d_return_json varchar;
	d_clave varchar;
BEGIN
	/*
	Hecho por: Vlade Párica

	Para probarlo:
					select sub_return_json_valueVD('{"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión"}]}','[{"clave":"categorias","posicion":0}]','idCategoria')

					select sub_return_json_valueVD('{"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión", "otro_nodo": {"tu_tia": "ana maria"} }] }','[{"clave":"categorias","posicion":1}, {"clave":"otro_nodo","posicion":0}]')
	*/
		d_long = json_array_length(i_position);


		select
			clave into d_clave
		from json_to_recordset(i_position) as
		(
			clave varchar,
			posicion integer
		)
		limit 1;


		select
			* into d_json
		from
			json_each(i_json)
		where
			key in (
					select
						clave
					from json_to_recordset(i_position) as
					(
						clave varchar,
						posicion integer
					)
					limit 1
		);

		if d_long > 1 then

			select json_agg(a.*) into strict i_position from (
				select
					*
				from json_to_recordset(i_position) as
				(
					clave varchar,
					posicion integer
				)
				where d_json.key <> clave
			) a;

			d_return_json = (select return_json_valueVD(d_json.value,i_position,i_clave));

		else

			if d_clave is null then
				d_return_json = d_json.value;
			else
				d_return_json = i_json;
			end if;

			if json_typeof(d_return_json::json) = 'array' then
				return 'El Json final es un array, no consta de claves';
			else
				i_clave = replace(i_clave,' ','');
				d_return_json = (SELECT d_return_json::json->>i_clave::text);
			end if;


		end if;


	if d_return_json is null then
		return 'La clave no existe';
	end if;

	RETURN d_return_json;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION sub_return_json_valueVD(json, json, varchar)
  OWNER TO postgres;
COMMENT ON FUNCTION sub_return_json_valueVD(json, json, varchar) IS 'sub_return_json_valueVD';
