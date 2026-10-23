-- Function: public.probando_locura(json)

-- DROP FUNCTION public.probando_locura(json);

CREATE OR REPLACE FUNCTION public.probando_locura(
	i_json json)
RETURNS json AS
$BODY$
DECLARE
	d_json json;
	d_record record;
	string varchar='';
BEGIN
	/*
	Hecho por: Vlade Párica
	Fecha:
	Resumen:

	Para probarlo:
					select probando_locura('[{"hola":"vlade"},{"hola":"dey"},{"hola":"Darda"}]')
	*/
	for d_record in (

			with array_tmp as (

			select
				value as values
			from
				json_array_elements(i_json)

		)

			select distinct
				key,
				json_typeof(value) as types
			from
				array_tmp,
				json_each(values)

	)
	loop
		string = string || d_record.key ||' '|| d_record.types ||', ';
	end loop;

	string = rtrim(string,', ');
	string = replace(string,'string','varchar');
	raise notice 'string %', string;
	execute



		'SELECT json_agg(a.*) FROM (

			select
				*
			from
				json_to_recordset('''||i_json||''') as
			(
				'||string||'
			)

		) a' into d_json;


	RETURN d_json::jsonb;
END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION public.probando_locura(json)
	OWNER TO postgres;
COMMENT ON FUNCTION public.probando_locura(json) IS 'Observacion';
