-- Function: search_jsonvd(json, json)

-- DROP FUNCTION search_jsonvd(json, json);

CREATE OR REPLACE FUNCTION search_jsonvd(
    i_json json,
    i_object_json json)
  RETURNS integer AS
$BODY$
DECLARE
	d_data record;
	d_object varchar = 'object';
	d_array varchar = 'array';
	d_execute varchar;
	d_type_data varchar;
	broke integer;
BEGIN
	/*
	Hecho por: Vlade Párica
	Fecha:
	Resumen:

	Para probarlo:
					select public.search_jsonVD('[{"tramites":[{"title":"Actualización","id":23,"tipostramites":null},{"title":"Autorización de","id":41,"tipostramites":[{"title":"Cambio de Dirección","idTipoTramiteGeneral":74,"clase":null,"tipoLicencias":[{"idTipoTramiteDetallado":483,"tipoLicencia":"No especificado","idTipoLicencia":0,"categorias":null}]}]},{"title":"Certificación de","id":38,"tipostramites":[{"title":"Horas de Vuelo","idTipoTramiteGeneral":80,"clase":0,"tipoLicencias":[{"idTipoTramiteDetallado":367,"tipoLicencia":"Instructor de Vuelo Avión","idTipoLicencia":12,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":511,"tipoLicencia":"Instructor de Vuelo de Dirigible","idTipoLicencia":30,"categorias":[{"idCategoria":4,"categoria":"Dirigible"}]},{"idTipoTramiteDetallado":510,"tipoLicencia":"Instructor de Vuelo de Planeador","idTipoLicencia":27,"categorias":[{"idCategoria":7,"categoria":"Planeador"}]},{"idTipoTramiteDetallado":372,"tipoLicencia":"Instructor de Vuelo Helicóptero","idTipoLicencia":22,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":378,"tipoLicencia":"Instructor de Vuelo RPA Ala Fija","idTipoLicencia":34,"categorias":[{"idCategoria":8,"categoria":"RPA Ala Fija"}]},{"idTipoTramiteDetallado":512,"tipoLicencia":"Instructor de Vuelo Ultraliviano","idTipoLicencia":24,"categorias":[{"idCategoria":5,"categoria":"Ultraliviano"}]},{"idTipoTramiteDetallado":368,"tipoLicencia":"Mecánico de a Bordo","idTipoLicencia":13,"categorias":null},{"idTipoTramiteDetallado":362,"tipoLicencia":"Piloto Comercial - Avión","idTipoLicencia":3,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":508,"tipoLicencia":"Piloto Comercial de Globo Libre","idTipoLicencia":23,"categorias":[{"idCategoria":6,"categoria":"Globo Libre"}]},{"idTipoTramiteDetallado":509,"tipoLicencia":"Piloto Comercial de Ultraliviano","idTipoLicencia":11,"categorias":[{"idCategoria":5,"categoria":"Ultraliviano"}]},{"idTipoTramiteDetallado":365,"tipoLicencia":"Piloto Comercial - Helicóptero","idTipoLicencia":6,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":507,"tipoLicencia":"Piloto de Dirigible","idTipoLicencia":29,"categorias":[{"idCategoria":4,"categoria":"Dirigible"}]},{"idTipoTramiteDetallado":504,"tipoLicencia":"Piloto de Globo Libre","idTipoLicencia":9,"categorias":[{"idCategoria":6,"categoria":"Globo Libre"}]},{"idTipoTramiteDetallado":505,"tipoLicencia":"Piloto de Planeador","idTipoLicencia":8,"categorias":[{"idCategoria":7,"categoria":"Planeador"}]},{"idTipoTramiteDetallado":506,"tipoLicencia":"Piloto de Ultraliviano","idTipoLicencia":10,"categorias":[{"idCategoria":5,"categoria":"Ultraliviano"}]},{"idTipoTramiteDetallado":361,"tipoLicencia":"Piloto Privado - Avión","idTipoLicencia":2,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":364,"tipoLicencia":"Piloto Privado - Helicóptero","idTipoLicencia":5,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":377,"tipoLicencia":"Piloto RPA Ala Fija","idTipoLicencia":33,"categorias":[{"idCategoria":8,"categoria":"RPA Ala Fija"}]},{"idTipoTramiteDetallado":379,"tipoLicencia":"Piloto RPA Ala Rotativa","idTipoLicencia":35,"categorias":[{"idCategoria":9,"categoria":"RPA Ala Rotativa"}]},{"idTipoTramiteDetallado":363,"tipoLicencia":"Piloto Transporte de Línea Aérea - Avión","idTipoLicencia":4,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":366,"tipoLicencia":"Piloto Transporte de Línea Aérea - Helicóptero","idTipoLicencia":7,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":369,"tipoLicencia":"Tripulante de Cabina","idTipoLicencia":14,"categorias":null}]},{"title":"Licencia y Certificado Médico","idTipoTramiteGeneral":54,"clase":0,"tipoLicencias":[{"idTipoTramiteDetallado":351,"tipoLicencia":"Controlador de Tránsito Aéreo","idTipoLicencia":17,"categorias":null},{"idTipoTramiteDetallado":484,"tipoLicencia":"Despachador de Vuelo","idTipoLicencia":19,"categorias":null},{"idTipoTramiteDetallado":347,"tipoLicencia":"Instructor de Vuelo Avión","idTipoLicencia":12,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":502,"tipoLicencia":"Instructor de Vuelo de Dirigible","idTipoLicencia":30,"categorias":[{"idCategoria":4,"categoria":"Dirigible"}]},{"idTipoTramiteDetallado":500,"tipoLicencia":"Instructor de Vuelo de Planeador","idTipoLicencia":27,"categorias":[{"idCategoria":7,"categoria":"Planeador"}]},{"idTipoTramiteDetallado":352,"tipoLicencia":"Instructor de Vuelo Helicóptero","idTipoLicencia":22,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":350,"tipoLicencia":"Instructor de Vuelo Instrumental Simulado","idTipoLicencia":16,"categorias":null},{"idTipoTramiteDetallado":358,"tipoLicencia":"Instructor de Vuelo RPA Ala Fija","idTipoLicencia":34,"categorias":[{"idCategoria":8,"categoria":"RPA Ala Fija"}]},{"idTipoTramiteDetallado":360,"tipoLicencia":"Instructor de Vuelo RPA Ala Rotativa","idTipoLicencia":36,"categorias":[{"idCategoria":9,"categoria":"RPA Ala Rotativa"}]},{"idTipoTramiteDetallado":503,"tipoLicencia":"Instructor de Vuelo Ultraliviano","idTipoLicencia":24,"categorias":[{"idCategoria":5,"categoria":"Ultraliviano"}]},{"idTipoTramiteDetallado":348,"tipoLicencia":"Mecánico de a Bordo","idTipoLicencia":13,"categorias":null},{"idTipoTramiteDetallado":486,"tipoLicencia":"Operador de Estaciones Aeronáuticas","idTipoLicencia":18,"categorias":null},{"idTipoTramiteDetallado":342,"tipoLicencia":"Piloto Comercial - Avión","idTipoLicencia":3,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":498,"tipoLicencia":"Piloto Comercial de Globo Libre","idTipoLicencia":23,"categorias":[{"idCategoria":6,"categoria":"Globo Libre"}]},{"idTipoTramiteDetallado":499,"tipoLicencia":"Piloto Comercial de Ultraliviano","idTipoLicencia":11,"categorias":[{"idCategoria":5,"categoria":"Ultraliviano"}]},{"idTipoTramiteDetallado":345,"tipoLicencia":"Piloto Comercial - Helicóptero","idTipoLicencia":6,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":495,"tipoLicencia":"Piloto de Globo Libre","idTipoLicencia":9,"categorias":[{"idCategoria":6,"categoria":"Globo Libre"}]},{"idTipoTramiteDetallado":496,"tipoLicencia":"Piloto de Planeador","idTipoLicencia":8,"categorias":[{"idCategoria":7,"categoria":"Planeador"}]},{"idTipoTramiteDetallado":497,"tipoLicencia":"Piloto de Ultraliviano","idTipoLicencia":10,"categorias":[{"idCategoria":5,"categoria":"Ultraliviano"}]},{"idTipoTramiteDetallado":341,"tipoLicencia":"Piloto Privado - Avión","idTipoLicencia":2,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":344,"tipoLicencia":"Piloto Privado - Helicóptero","idTipoLicencia":5,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":357,"tipoLicencia":"Piloto RPA Ala Fija","idTipoLicencia":33,"categorias":[{"idCategoria":8,"categoria":"RPA Ala Fija"}]},{"idTipoTramiteDetallado":359,"tipoLicencia":"Piloto RPA Ala Rotativa","idTipoLicencia":35,"categorias":[{"idCategoria":9,"categoria":"RPA Ala Rotativa"}]},{"idTipoTramiteDetallado":343,"tipoLicencia":"Piloto Transporte de Línea Aérea - Avión","idTipoLicencia":4,"categorias":[{"idCategoria":2,"categoria":"Avión"}]},{"idTipoTramiteDetallado":346,"tipoLicencia":"Piloto Transporte de Línea Aérea - Helicóptero","idTipoLicencia":7,"categorias":[{"idCategoria":3,"categoria":"Helicóptero"}]},{"idTipoTramiteDetallado":354,"tipoLicencia":"Técnico en Mantenimiento de Aeronaves","idTipoLicencia":28,"categorias":null},{"idTipoTramiteDetallado":349,"tipoLicencia":"Tripulante de Cabina","idTipoLicencia":14,"categorias":null}]}]},{"title":"Convalidación de Licencia Aeronáutica","id":18,"tipostramites":null},{"title":"Duplicado de Licencia Aeronáutica","id":17,"tipostramites":null},{"title":"Emisión de Licencia Aeronáutica","id":15,"tipostramites":null},{"title":"Otorgamiento de","id":24,"tipostramites":null},{"title":"Otorgamiento de Habilitación Aeronáutica","id":22,"tipostramites":null},{"title":"Renovación de Licencia Aeronáutica","id":16,"tipostramites":null}]}]','{"title":"Duplicado de Licencia Aeronáutica","id":17,"tipostramites":null}')

					select search_jsonVD('{"idTipoTramiteDetallado": 367, "tipoLicencia": "Instructor de Vuelo Avión", "idTipoLicencia": 12, "categorias": [{"idCategoria": 2, "categoria": "Avión"}]}','[{"idCategoria": 2, "categoria": "Avión"}]')
					*/

	--elimino los espacios en blanco

	i_json = replace(i_json::varchar, ' ', '');
	i_object_json = replace(i_object_json::varchar, ' ', '');
	i_json = i_json::jsonb;
	i_object_json = i_object_json::jsonb;

	if i_object_json::varchar like '[%' and i_object_json::varchar like '%]' then
		i_object_json = ltrim(rtrim(i_object_json::varchar , ']'), '[');
	end if;


	if i_json::varchar like '{%' and i_json::varchar like '%}' then
		i_json = '['||i_json||']';
	end if;

d_execute = 'with destructor_tmp as (

		  		select
		 			*
		 		from
		 			jsonb_array_elements($$'||i_json||'$$::jsonb) with ordinality arr(elem, position)
		  ), select_tmp as (

			  	select
			  		*,
			  		json_typeof(elem::json) as elems
			  	from
			  		destructor_tmp,
			  		json_each(elem::json)

		  ), search_json as (

		  	select
				elem,
				position,
				key,
				(select convert_array_jsonVD(elem::varchar)) as value,
			  	json_typeof(value::json) as datos,
			  	value as value_inicial
		  	from
		  		select_tmp
		  	where
		  	(elem::varchar = $$'||i_object_json||'$$::varchar) or (value::varchar = $$'||i_object_json||'$$::varchar)

		  	union all

		  	select
				elem,
				position,
				key,
				case
					WHEN json_typeof(value::json) = $$'||d_object||'$$ THEN (select (''[''||value||'']'')::json)
					ELSE value
				end,
		  		json_typeof(value::json) as datos,
		  		value as value_inicial
		  	from
		  		select_tmp
		  	where
		  	(json_typeof(value::json) like $$'||d_object||'$$ or
		  	json_typeof(value::json) like $$'||d_array||'$$)
		  	order by datos asc
		  )
		  	select
		  		*
		  	from
		  		search_json'
		  ;


	  for d_data in execute d_execute
	  loop

	  if ((replace(d_data.value::varchar, ' ', '') = replace('['||i_object_json||']'::varchar, ' ', '')) or (replace(d_data.elem::varchar, ' ', '') = replace(i_object_json::varchar, ' ', '')) or (replace(d_data.value_inicial::varchar, ' ', '') = replace(i_object_json::varchar, ' ', ''))) then

	  		return 1;
	  end if;

	  if not d_data.datos is null then
	  	broke = (select public.search_jsonVD(d_data.value,i_object_json));
	  end if;

	  if broke <> 0 then
	  	return broke;
	  end if;

	  end loop;

	RETURN 0;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION search_jsonvd(json, json)
  OWNER TO postgres;
COMMENT ON FUNCTION search_jsonvd(json, json) IS 'search_jsonVD';
