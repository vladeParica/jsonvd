-- Function: public.compare_jsonVD(json, json)

-- DROP FUNCTION public.compare_jsonVD(json, json);

CREATE OR REPLACE FUNCTION public.compare_jsonVD(
	i_jsona json,
	i_jsonb json)
RETURNS varchar AS
$BODY$
DECLARE
	d_data record;
BEGIN
	/*
	Hecho por: Vlade Párica
	Fecha:
	Resumen:

	Para probarlo:
						select compare_jsonVD('[{"title":"Cambio de Dirección","idTipoTramiteGeneral":74,"clase":null,"tipoLicencias":[{"idTipoTramiteDetallado":483,"tipoLicencia":"No especificado","idTipoLicencia":0,"categorias":null}]}]','[{"title":"Cambio de Dirección","idTipoTramiteGeneral":74,"clase":null,"tipoLicencias":[{"idTipoTramiteDetallado":483,"tipoLicencia":"No especificado","idTipoLicencia":0,"categorias":null}]}]')


							select public.compare_jsonVD('{"idTipoTramiteDetallado":367,"tipoLicencia":"Instructor de Vuelo Avión","idTipoLicencia":12,"categorias":[{"idCategoria":2,"categoria":"Avión"}]}','{"idTipoTramiteDetallado":367,"tipoLicencia":"Instructor de Vuelo Avión","idTipoLicencia":12,"categorias":[{"idCategoria":2,"categoria":"Avión"}]}')
	*/

	i_jsona = replace(i_jsona::varchar, ' ', '');
	i_jsonb = replace(i_jsonb::varchar, ' ', '');
	i_jsona = i_jsona::jsonb;
	i_jsonb = i_jsonb::jsonb;

	if i_jsona::varchar like '{%' and i_jsona::varchar like '%}' and i_jsonb::varchar like '{%' and i_jsonb::varchar like '%}' then

		  with compare_jsons_tmp as (

		  		select
		  			*
		  		from json_each(i_jsona)

		  		union all

		  		select
		  			*
		  		from json_each(i_jsonb)
		  )
		  	select distinct
		  		key,
		  		value::varchar,
		  		count(key) as total
		  	into d_data
		  	from
		  		compare_jsons_tmp
		  	group by key,value::varchar
		  	having count(key)%2 <> 0
		  ;

	end if;

	if i_jsona::varchar like '[%' and i_jsona::varchar like '%]' and i_jsonb::varchar like '[%' and i_jsonb::varchar like '%]' then

		  with compare_jsons_tmp as (

		  		select
		  			*
		  		from jsonb_array_elements(i_jsona::jsonb)

		  		union all

		  		select
		  			*
		  		from jsonb_array_elements(i_jsonb::jsonb)
		  )
		  	select distinct
		  		value::varchar,
		  		count(value) as total
		  	into d_data
		  	from
		  		compare_jsons_tmp
		  	group by value::varchar
		  	having count(value)%2 <> 0
		  ;

	end if;

  	if d_data.total is null then
  		return 'Jsons iguales';
  	end if;


	RETURN 'Jsons Distintos';
END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION public.compare_jsonVD(json, json)
	OWNER TO postgres;
COMMENT ON FUNCTION public.compare_jsonVD(json, json) IS 'compare_jsonVD';
