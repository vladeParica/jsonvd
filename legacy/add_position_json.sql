-- Function: add_position_jsonVD(json, json, varchar, varchar)

-- DROP FUNCTION add_position_jsonVD(json, json, varchar, varchar);

CREATE OR REPLACE FUNCTION add_position_jsonVD(
	i_json json,
	i_json_position json,
	i_clave varchar,
	i_value varchar)
RETURNS varchar AS
$BODY$
DECLARE
	d_router varchar;
	d_json varchar;
	String varchar;
	d_values record;
	d_long integer;
	d_record record;
	d_array varchar = '$$array$$';
	d_object varchar = '$$object$$';
BEGIN
	/*
	Hecho por: Vlade Párica

	Para probarlo:
					select add_position_jsonVD('[{"x": 45, "demenecia": 458 }, {"y": 78, "locura": 458 }, {"ezz": {"z": 15, "desquiciado": 357, "nodo_pro": [{"jarvis": "locote"}, {"normal": 45 }] } }]','[{"clave": "ezz", "posicion": 2}, {"clave": "nodo_pro", "posicion": 0}, {"posicion": 1}]','prueba','{"prueba":1 ,"rawayana":"sin ti"}')


 					select add_position_jsonVD('[{"tx_esp": "Cardiología", "id_especialidadesmed": 4, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenCardiovascular_1528813590.pdf", "fecha": "12-06-018", "id_especialidadesmed": 4, "tx_esp": "Cardiología", "id_recaudo": 158, "ruta": "http://192.168.0.200//file/arch/15990.pdf", "descripcion": "Reporte Cardiología"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }, {"tx_esp": "Medicina General", "id_especialidadesmed": 1, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenMedicoGeneral_1528813588.pdf", "fecha": "12-06-018", "id_especialidadesmed": 1, "tx_esp": "Medicina General", "id_recaudo": 155, "ruta": "http://192.168.0.200//file/arch/15987.pdf", "descripcion": "Reporte Medicina General"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }, {"tx_esp": "Neurología", "id_especialidadesmed": 5, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenNeurologico_1528813591.pdf", "fecha": "12-06-018", "id_especialidadesmed": 5, "tx_esp": "Neurología", "id_recaudo": 159, "ruta": "http://192.168.0.200//file/arch/15991.pdf", "descripcion": "Reporte Neurología"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }, {"tx_esp": "Odontología", "id_especialidadesmed": 8, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenOdontologia_1528813593.pdf", "fecha": "12-06-018", "id_especialidadesmed": 8, "tx_esp": "Odontología", "id_recaudo": 162, "ruta": "http://192.168.0.200//file/arch/15994.pdf", "descripcion": "Reporte Odontología"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }, {"tx_esp": "Oftalmología", "id_especialidadesmed": 3, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenOftalmologico_1528813590.pdf", "fecha": "12-06-018", "id_especialidadesmed": 3, "tx_esp": "Oftalmología", "id_recaudo": 157, "ruta": "http://192.168.0.200//file/arch/15989.pdf", "descripcion": "Reporte Oftalmología"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }, {"tx_esp": "Otorrinolaringología", "id_especialidadesmed": 2, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenOtorrinolaringologico_1528813589.pdf", "fecha": "12-06-018", "id_especialidadesmed": 2, "tx_esp": "Otorrinolaringología", "id_recaudo": 156, "ruta": "http://192.168.0.200//file/arch/15988.pdf", "descripcion": "Reporte Otorrinolaringología"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }, {"tx_esp": "Psicología", "id_especialidadesmed": 6, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenPsicologico_1528813592.pdf", "fecha": "12-06-018", "id_especialidadesmed": 6, "tx_esp": "Psicología", "id_recaudo": 160, "ruta": "http://192.168.0.200//file/arch/15992.pdf", "descripcion": "Reporte Psicología"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }, {"tx_esp": "Psiquiatría", "id_especialidadesmed": 7, "tramite": [{"evaluacion_inicial": [{"id_solicitud": 831, "clase_medicina": 2, "id_tipo_tramite": 50, "id_tramite": 649, "descripcion_archivo": "ExamenPsiquiatria_1528813592.pdf", "fecha": "12-06-018", "id_especialidadesmed": 7, "tx_esp": "Psiquiatría", "id_recaudo": 161, "ruta": "http://192.168.0.200//file/arch/15993.pdf", "descripcion": "Reporte Psiquiatría"}], "evaluacion_periodica": null, "evaluacion_extraordinaria": null, "auditoria": null }] }]','[{"clave": "tramite", "posicion": 6}, {"clave": "evaluacion_inicial", "posicion": 0}, {"posicion": 0}]','prueba2','true')
	-- */

	d_long = json_array_length(i_json_position);

	with destruc_position_tmp as (

		select
			value->>'clave' as clave,
			value->>'posicion' as posicion
		from
			json_array_elements(i_json_position)
		limit 1

	)
		select
			* into d_values
		from
			destruc_position_tmp
	;


	if json_typeof(i_json) = 'object' then
		d_router = '->$$'||d_values.clave||'$$';
	else

		if d_long = 1 then
			d_router = '->'||d_values.posicion;
		else
			d_router = '->'||d_values.posicion||'->$$'||d_values.clave||'$$';
		end if;

	end if;

	execute 'select $$'||i_json||'$$::json'||d_router into d_json;
	d_router = '';

	String ='
		with position_tmp as (

			select
				value,
				ordinality as position
			from
				json_array_elements($$'||i_json_position||'$$)
				with ordinality
			order by position desc

		), json_position_tmp as (

			select
				*
			from
				position_tmp
			limit '||d_long-1||'

		)
			select
				value
			from
				json_position_tmp
			order by position
	';

	for d_record in execute String
	loop
		d_router = d_router || d_record.value ||'#';
	end loop;

	if d_long > 1 then
		d_json = add_position_jsonVD(d_json::json,convert_array_jsonvd(rtrim(d_router,'#')),i_clave,i_value);
		d_router = '';
	end if;



if d_long = 1 then
	d_json = json_push_vd(d_json::json,i_clave,i_value);
end if;
	-----------------------------------------------------------------------------------------------------------------------------------------

	if json_typeof(i_json) = 'array' then


		if not d_values.clave is null and json_typeof(d_json::json) = 'object' then

			string = '
					select
						$$'||d_values.clave||'$$ as elem,
						$$'||d_json||'$$ as position';


			for d_record in execute string
			loop
				d_router = d_router ||'$$'|| d_record.elem::varchar ||'$$,$$'|| d_record.position::varchar || '$$,';
			end loop;

			d_router = rtrim(d_router,',');

			execute 'select to_json_build_vd('||d_router||')' into d_json;

		end if;

		-----------------------------------------------------------------------------------------------------------------------------------------

		if json_typeof(d_json::json) = 'array' and not d_values.clave is null then

			String ='

				with json_array_tmp as (

					select
						elems,
						(positions -1) as positions
					from
						json_array_elements($$'||i_json||'$$) with ordinality arr(elems, positions)

				), each_tmp as (

					select
						elem,
						position,
						(ordinality -1) as ordinality
					from
						json_array_tmp,
						json_each(elems) with ordinality arr(elem, position)
					where
						positions = '||d_values.posicion||'

				), select_position_tmp as (

					select
						ordinality
					from
						each_tmp
					where
						elem = $$'||d_values.clave||'$$

				)
					select
						*
					from
						each_tmp
					where
						elem <> $$'||d_values.clave||'$$

					union all

					select
						$$'||d_values.clave||'$$ as elem,
						$$'||d_json||'$$ as position,
						(select * from select_position_tmp) as ordinality
					order by ordinality';


			for d_record in execute string
			loop
				if d_record.position is null then
					d_record.position = 'null';
				end if;
				d_router = d_router ||'$$'|| d_record.elem ||'$$,$$'|| d_record.position || '$$,';
			end loop;

			d_router = rtrim(d_router,',');

			execute 'select to_json_build_vd('||d_router||')' into d_json;
			String = '';




			String = '
				with json_construc_tmp as (

					select
						elems,
						(positions -1) as positions
					from
						json_array_elements($$'||i_json||'$$) with ordinality arr(elems, positions)

				), json_array_final_tmp as (

					select
						*
					from
						json_construc_tmp
					where
						positions <> '||d_values.posicion||'

					union all

					select
						$$'||d_json||'$$ as elems,
						'||d_values.posicion||' as positions
					order by positions
				)
					select
						elems as value
					from
						json_array_final_tmp';

			d_json = query_convert_array_jsonVD(String);
			-----------------------------------------------------------------------------------------------------------------

		else
			-----------------------------------------------------------------------------------------------------------------
			String ='

				with json_array_tmp as (

					select
						elem,
						(position -1) as position
					from
						json_array_elements($$'||i_json||'$$) with ordinality arr(elem, position)

				), agg_tmp as (

					select
						elem as value,
						position
					from
						json_array_tmp
					where
						position <> '||d_values.posicion||'

					union all


					select
						$$'||d_json||'$$ as value,
						'||d_values.posicion||' as position
					order by position

				)

					select
						value
					from
						agg_tmp';

			d_json = query_convert_array_jsonVD(String);

		end if;
		----------------------------------------------------------------------------------------------------------------------------------------------
	else
		----------------------------------------------------------------------------------------------------------------------------------------------
		string = '

			with json_tmp as (

				select
					elem,
					position,
					(ordinality -1) as ordinality
				from
					json_each($$'||i_json||'$$) with ordinality arr(elem, position)

			), select_position_tmp as (

				select
					ordinality
				from
					json_tmp
				where
					elem = $$'||d_values.clave||'$$

			), to_json_tmp as (

				select
					*
				from
					json_tmp
				where
					elem <> $$'||d_values.clave||'$$

			)

				select
					*
				from
					to_json_tmp

				union all

				select
					$$'||d_values.clave||'$$ as elem,
					$$'||d_json||'$$ as position,
					(select * from select_position_tmp) as ordinality

				order by ordinality';

		for d_record in execute string
		loop
			if d_record.position is null then
				d_record.position = 'null';
			end if;
			d_router = d_router ||'$$'|| d_record.elem ||'$$,'''|| d_record.position || ''',';
		end loop;

		d_router = rtrim(d_router,',');

		execute 'select to_json_build_vd('||d_router||')' into d_json;

		-----------------------------------------------------------------------------------------------------------------------------------------
	end if;


	RETURN d_json;
END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
ALTER FUNCTION add_position_jsonVD(json, json, varchar, varchar)
	OWNER TO postgres;
COMMENT ON FUNCTION add_position_jsonVD(json, json, varchar, varchar) IS 'add_position_jsonVD';
