-- Function: return_json_valueVD(json, json, varchar)

-- DROP FUNCTION return_json_valueVD(json, json, varchar);

CREATE OR REPLACE FUNCTION return_json_valueVD(
    i_json json,
    i_position json,
    i_clave varchar)
  RETURNS character varying AS
$BODY$
DECLARE
	d_json record;
	d_return_json varchar;
BEGIN
	/*
	Hecho por: Vlade Párica

	Para probarlo:
					select return_json_valueVD('[{"song:":"Somebody told me","banda":"The killers"},{"song:":"Miss Atomic Bomb","banda":"The killers"},{"song:":"Fix you","banda":"Coldplay","nodo_maluma":[{"song":"Tu me partiste el corazon","banda":"maluma"},{"song":"mientes","banda":"camila"}],"solista":{"song":"Let me","cantante":"zayn"}}]','[{"clave":"nodo_maluma","posicion":2},{"posicion":1}]','song')

					select return_json_valueVD('[{"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión"}] }, {"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión"}] }, {"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "helicoptero"}] }]','[{"clave":"categorias","posicion":2}]','tipoLicencia')

					select return_json_valueVD('[{"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión"}] }, {"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión", "otro_nodo": {"tu_tia": "ana maria"} }] }, {"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión"}] }]',' [{"clave":"categorias","posicion":1}, {"clave":"otro_nodo","posicion":0}]')


*/

		if (
				select
					true
				from json_to_recordset(i_position) as
				(
					clave varchar,
					posicion integer
				)
				where clave is null


			) then

				select json_agg(a.*) into strict i_position from (
					select
						*
					from json_to_recordset(i_position) as
					(
						clave varchar,
						posicion integer
					)
				) a;

				i_position = replace(i_position::varchar,'null','0');
		end if;

	if json_typeof(i_json::json) = 'object' then

		d_return_json = (select sub_return_json_valueVD(i_json,i_position,i_clave));

	else

		select
			elem,
			position-1 as position
		into d_json
		from
			json_array_elements(i_json) with ordinality arr(elem, position)
		where
			(position-1) in (
							select
								posicion
							from json_to_recordset(i_position) as
							(
								clave varchar,
								posicion integer
							)
							limit 1
			);

			d_return_json = (select sub_return_json_valueVD(d_json.elem,i_position,i_clave));

	end if;

	RETURN d_return_json;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION return_json_valueVD(json, json, varchar)
  OWNER TO postgres;
COMMENT ON FUNCTION return_json_valueVD(json, json, varchar) IS 'return_json_valueVD';
