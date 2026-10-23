-- Function: public.convert_array_jsonVD(varchar)

-- DROP FUNCTION public.convert_array_jsonVD(varchar);

CREATE OR REPLACE FUNCTION public.convert_array_jsonVD(
	jsons varchar)
RETURNS json AS
$BODY$
DECLARE
	error_MESSAGE_TEXT varchar;
	d_json record;
BEGIN
	/*
	Hecho por: Vlade Párica

	Para probarlo:
					select convert_array_jsonVD('{"hola":[{"hoy":1}],"hola":{"go":78}}#{"tutia":"ana maria"}#{"hola":78,"no se":4}')
	*/


		for d_json in (

			with json_valider_tmp as (

				select
					regexp_split_to_table as json
				from
					regexp_split_to_table(jsons,'#')

			)
				select
					*
				from
					json_valider_tmp
		)
		loop

			if  d_json.json like '[{%%}]' then
				return json_build_object('ERROR','Todos los elementos deben ser objects');
			end if;

			d_json.json = (select d_json.json :: json);


			if d_json.json = '{}' then
				return json_build_object('ERROR','No se puede convertir en array por existir objects vacios {} ');
			end if;

		end loop;


		RETURN replace('['||jsons||']','}#{','},{');

		EXCEPTION
		WHEN others THEN
		GET STACKED DIAGNOSTICS
		error_MESSAGE_TEXT = MESSAGE_TEXT;

		jsons = json_build_object('ERROR',error_MESSAGE_TEXT);

		return jsons;

END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION public.convert_array_jsonVD(varchar)
	OWNER TO postgres;
COMMENT ON FUNCTION public.convert_array_jsonVD(varchar) IS 'convert_array_jsonVD';
