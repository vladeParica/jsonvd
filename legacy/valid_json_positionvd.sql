-- Function: valid_json_positionvd(json)

-- DROP FUNCTION valid_json_positionvd(json);

CREATE OR REPLACE FUNCTION valid_json_positionvd(i_json json)
  RETURNS json AS
$BODY$
DECLARE

BEGIN
	/*
	Hecho por: Vlade Párica

	Para probarlo:
					select valid_json_positionVD('[{"clave":"categorias","posicion":1}, {"clave":"otro_nodo","posicion":0}]')
	*/

		if (
				select
					true
				from json_to_recordset(i_json) as
				(
					clave varchar,
					posicion integer
				)
				where clave is null


			) then

				select json_agg(a.*) into strict i_json from (
					select
						*
					from json_to_recordset(i_json) as
					(
						clave varchar,
						posicion integer
					)
				) a;

				i_json = replace(i_json::varchar,'null','0');
		end if;


	RETURN i_json;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION valid_json_positionvd(json)
  OWNER TO postgres;
COMMENT ON FUNCTION valid_json_positionvd(json) IS 'valid_json_positionVD';
