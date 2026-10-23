-- Function: sub_return_jsonvd(json, json)

-- DROP FUNCTION sub_return_jsonvd(json, json);

CREATE OR REPLACE FUNCTION sub_return_jsonvd(
    i_json json,
    i_position json)
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
					select sub_return_jsonVD('{"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión"}]}','[{"clave":"categorias","posicion":0}]')

					select sub_return_jsonVD('{"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión", "otro_nodo": {"tu_tia": "ana maria"} }] }','[{"clave":"categorias","posicion":1}, {"clave":"otro_nodo","posicion":0}]')
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

			d_return_json = (select return_jsonVD(d_json.value,i_position));

		else

			if d_clave is null then
				d_return_json = d_json.value;
			else
				d_return_json = i_json;
			end if;

		end if;

	if d_return_json is null then
		return 'No existe';
	end if;

	RETURN d_return_json;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION sub_return_jsonvd(json, json)
  OWNER TO postgres;
COMMENT ON FUNCTION sub_return_jsonvd(json, json) IS 'sub_return_jsonVD';
