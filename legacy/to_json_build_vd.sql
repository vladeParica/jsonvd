-- Function: to_json_build_vd(character varying[])

-- DROP FUNCTION to_json_build_vd(character varying[]);

CREATE OR REPLACE FUNCTION to_json_build_vd(VARIADIC valor character varying[])
  RETURNS character varying AS
$BODY$
DECLARE
	d_parameters record;
	d_length integer;
	jsons json;
	error_MESSAGE_TEXT varchar;
	validated json;
	query text default 'Select ';
	d_return json;
	d_clave varchar;
	d_type varchar;
BEGIN
	/*
	Hecho por: Vlade Párica - Dey
	Fecha: 08-06-2018
	Resumen:

	Para probarlo:
					select to_json_build_vd('15','{"hola":"hola"}','HOLA','hola','prueba','1','boolean','true','array','[]')
	*/

	d_length = array_length(valor,1);



	if d_length % 2 = 0 then -- solo si es par es porque estan completos sus (clave : valor)

		for d_parameters in 1 .. d_length
		loop

			if not d_parameters % 2 = 0 then

				-- validando que no esten erroneas las claves
				select
					'{}' into validated
				where
					valor[d_parameters] like '%[%' or
					valor[d_parameters] like '%]%' or
					valor[d_parameters] like '%{%' or
					valor[d_parameters] like '%}%' or
					valor[d_parameters] like '%:%';


				if validated::varchar = '{}' then

					 return replace(json_build_object('ERROR','la sintaxis de entrada no es válida para la clave: '||valor[d_parameters]||' ')::varchar,(CHR(92)||'"'),'"');
				end if;

			end if;

			--raise notice 'd_parameters %', valor[d_parameters];

			IF (d_parameters % 2 = 0) THEN

				d_type = typeof_vd(valor[d_parameters]::text);

				IF ( d_type = 'text' or d_type = 'json' or d_type = 'date') THEN

					query :=  query || '''' || trim(valor[d_parameters],'"') || '''' || '::' || d_type || ' AS '|| '"' || d_clave || '", ';

				ELSEIF (d_type = 'null') THEN

					query :=  query || valor[d_parameters]|| '::' || d_type || ' AS '|| '"' || d_clave || '", ';

				ELSE
					query :=  query || valor[d_parameters]|| ' AS '|| '"' || d_clave || '", ';
				END IF;
			ELSE
				--raise notice '1';
				d_clave :=  valor[d_parameters];
			END IF;

		end loop;

		query := rtrim(query::text,', ');

		execute 'SELECT to_json(a.*) FROM ( '
			|| query ||
		') a' into d_return;
	else

		return json_build_object('ERROR','la sintaxis de entrada no es válida cantidad de parametros incongruentes');

	end if;

	RETURN d_return;

	EXCEPTION
	WHEN others THEN
	GET STACKED DIAGNOSTICS
	error_MESSAGE_TEXT = MESSAGE_TEXT;

	jsons = json_build_object('ERROR',error_MESSAGE_TEXT);

	return jsons;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION to_json_build_vd(character varying[])
  OWNER TO postgres;
