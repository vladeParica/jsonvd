-- Compatibility layer for the original procedures (legacy/ folder).
--
-- Creates the functions with their old names and signatures in the current
-- schema (usually public), implemented on top of the jsonvd extension. Use it
-- to migrate systems that already call the old names without touching them.
--
--   psql -d mydb -f compat/jsonvd_legacy.sql
--
-- Intentional differences from the originals:
--   * No longer break on quotes, apostrophes, '#', '$$' or empty arrays.
--   * Invalid input raises an error instead of returning {"ERROR": ...}.
--   * json_push_vd infers types correctly ('1' -> 1, 'false' -> false) and
--     keeps the key's case.
--   * compare_jsonVD compares deeply and does not ignore spaces inside strings.
--   * The original Spanish result messages are kept ('No existe', etc.) so
--     existing callers that compare against them keep working.

CREATE EXTENSION IF NOT EXISTS jsonvd;

-------------------------------------------------------------------------------
-- Types and building
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION typeof_vd(i_value text)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT CASE jsonb_typeof(jsonvd.parse_value(i_value))
		WHEN 'null'    THEN 'NULL'
		WHEN 'boolean' THEN 'boolean'
		WHEN 'number'  THEN CASE WHEN btrim(i_value) ~ '^-?[0-9]+$' THEN 'int' ELSE 'numeric' END
		WHEN 'object'  THEN 'json'
		WHEN 'array'   THEN 'json'
		ELSE CASE WHEN btrim(i_value) ~ '^\d{4}-\d{2}-\d{2}$' THEN 'date' ELSE 'text' END
	END
$$;

CREATE OR REPLACE FUNCTION to_json_build_vd(VARIADIC valor varchar[])
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT jsonvd.build_object(VARIADIC valor::text[])::varchar $$;

CREATE OR REPLACE FUNCTION json_agg_build_vd(VARIADIC valor varchar[])
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT jsonb_build_array(jsonvd.build_object(VARIADIC valor::text[]))::varchar $$;

-- Joins '#'-separated objects. A '#' inside a string no longer breaks it:
-- fragments are accumulated until they form valid JSON.
CREATE OR REPLACE FUNCTION convert_array_jsonVD(jsons varchar)
RETURNS json
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
	piece text;
	pending text := NULL;
	elem jsonb;
	result jsonb := '[]';
BEGIN
	FOREACH piece IN ARRAY string_to_array(jsons, '#') LOOP
		pending := CASE WHEN pending IS NULL THEN piece ELSE pending || '#' || piece END;
		BEGIN
			elem := pending::jsonb;
		EXCEPTION WHEN data_exception THEN
			CONTINUE;
		END;
		IF jsonb_typeof(elem) <> 'object' THEN
			RAISE EXCEPTION 'convert_array_jsonVD: every element must be an object'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
		result := result || jsonb_build_array(elem);
		pending := NULL;
	END LOOP;

	IF pending IS NOT NULL THEN
		RAISE EXCEPTION 'convert_array_jsonVD: invalid JSON: %', pending
			USING ERRCODE = 'invalid_text_representation';
	END IF;

	RETURN result::json;
END;
$$;

CREATE OR REPLACE FUNCTION probando_locura(i_json json)
RETURNS json
LANGUAGE plpgsql STABLE STRICT
AS $$
DECLARE
	result json;
BEGIN
	EXECUTE format(
		'SELECT json_agg(t) FROM jsonb_to_recordset($1) AS t(%s)',
		jsonvd.recordset_definition(i_json::jsonb))
	INTO result
	USING i_json::jsonb;
	RETURN result;
END;
$$;

-------------------------------------------------------------------------------
-- Add / delete
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION json_push_vd(i_json json, i_clave varchar, i_value varchar)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT CASE json_typeof(i_json)
		WHEN 'array' THEN
			(i_json::jsonb || jsonb_build_array(jsonb_build_object(i_clave, jsonvd.parse_value(i_value))))::varchar
		ELSE
			jsonvd.push(i_json::jsonb, i_clave::text, i_value::text)::varchar
	END
$$;

CREATE OR REPLACE FUNCTION json_pushVD(i_json json, i_clave varchar, i_value varchar)
RETURNS json
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT jsonvd.push(i_json::jsonb, trim(i_clave, '"'), i_value::text)::json $$;

CREATE OR REPLACE FUNCTION json_pushVD(i_json json, i_clave varchar, i_value integer)
RETURNS json
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT jsonvd.push(i_json::jsonb, trim(i_clave, '"'), to_jsonb(i_value))::json $$;

CREATE OR REPLACE FUNCTION json_pushVD(i_json json, i_clave varchar, i_value boolean)
RETURNS json
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT jsonvd.push(i_json::jsonb, trim(i_clave, '"'), to_jsonb(i_value))::json $$;

CREATE OR REPLACE FUNCTION json_deleteVD(i_json json, i_clave varchar)
RETURNS json
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
	IF json_typeof(i_json) <> 'object' THEN
		RAISE EXCEPTION 'json_deleteVD: a key can only be deleted from an object'
			USING ERRCODE = 'invalid_parameter_value';
	END IF;
	RETURN (i_json::jsonb - trim(i_clave, '"'))::json;
END;
$$;

CREATE OR REPLACE FUNCTION json_deleteVD(i_json json, i_clave varchar, i_position integer)
RETURNS json
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
	IF json_typeof(i_json) <> 'array' THEN
		RAISE EXCEPTION 'json_deleteVD: expected an array, a key and a position'
			USING ERRCODE = 'invalid_parameter_value';
	END IF;
	IF jsonb_typeof(i_json::jsonb -> i_position) IS DISTINCT FROM 'object' THEN
		RAISE EXCEPTION 'json_deleteVD: position % is not an object', i_position
			USING ERRCODE = 'invalid_parameter_value';
	END IF;
	RETURN (i_json::jsonb #- ARRAY[i_position::text, trim(i_clave, '"')])::json;
END;
$$;

CREATE OR REPLACE FUNCTION add_position_jsonVD(i_json json, i_json_position json, i_clave varchar, i_value varchar)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT jsonvd.set_path(
		i_json::jsonb,
		jsonvd.legacy_path(i_json::jsonb, i_json_position::jsonb) || i_clave::text,
		jsonvd.parse_value(i_value))::varchar
$$;

-------------------------------------------------------------------------------
-- Compare / search
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION compare_jsonVD(i_jsona json, i_jsonb json)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT CASE WHEN i_jsona::jsonb = i_jsonb::jsonb THEN 'Jsons iguales' ELSE 'Jsons Distintos' END
$$;

-- The originals accepted '[x]' to search for x; that shortcut is kept.
CREATE OR REPLACE FUNCTION search_jsonVD(i_json json, i_object_json json)
RETURNS integer
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT (
		jsonvd.contains_deep(i_json::jsonb, i_object_json::jsonb)
		OR (json_typeof(i_object_json) = 'array'
			AND json_array_length(i_object_json) = 1
			AND jsonvd.contains_deep(i_json::jsonb, i_object_json::jsonb -> 0))
	)::integer
$$;

CREATE OR REPLACE FUNCTION search_positionVD(i_json json, i_object_json json)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT coalesce(
		jsonvd.to_legacy_path(
			i_json::jsonb,
			coalesce(
				jsonvd.find_path(i_json::jsonb, i_object_json::jsonb),
				CASE WHEN json_typeof(i_object_json) = 'array' AND json_array_length(i_object_json) = 1
					THEN jsonvd.find_path(i_json::jsonb, i_object_json::jsonb -> 0)
				END))::varchar,
		'No se encuentra el objecto')
$$;

CREATE OR REPLACE FUNCTION valid_json_positionVD(i_json json)
RETURNS json
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT coalesce(
		json_agg(
			json_build_object('clave', s.value ->> 'clave',
			                  'posicion', coalesce((s.value ->> 'posicion')::integer, 0))
			ORDER BY s.ord),
		'[]'::json)
	FROM json_array_elements(i_json) WITH ORDINALITY AS s(value, ord)
$$;

-------------------------------------------------------------------------------
-- Read by legacy path [{"clave","posicion"}]
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION return_jsonVD(i_json json, i_position json)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT coalesce(
		(i_json::jsonb #> jsonvd.legacy_path(i_json::jsonb, i_position::jsonb))::varchar,
		'No existe')
$$;

CREATE OR REPLACE FUNCTION sub_return_jsonVD(i_json json, i_position json)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT return_jsonVD(i_json, i_position) $$;

CREATE OR REPLACE FUNCTION return_json_valueVD(i_json json, i_position json, i_clave varchar)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT CASE
		WHEN jsonb_typeof(node) = 'array' THEN 'El Json final es un array, no consta de claves'
		ELSE coalesce(node ->> replace(i_clave, ' ', ''), 'La clave no existe')
	END
	FROM (SELECT i_json::jsonb #> jsonvd.legacy_path(i_json::jsonb, i_position::jsonb)) AS t(node)
$$;

CREATE OR REPLACE FUNCTION sub_return_json_valueVD(i_json json, i_position json, i_clave varchar)
RETURNS varchar
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT return_json_valueVD(i_json, i_position, i_clave) $$;
