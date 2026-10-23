-- jsonvd 1.0.0
-- Original idea and author: Vlade Párica
--
-- Design rules:
--   * jsonb in, jsonb out.
--   * No dynamic SQL: nothing is concatenated into text and executed.
--   * Errors are raised (RAISE), never returned as data.
--   * IMMUTABLE PARALLEL SAFE for everything that is pure.

\echo Use "CREATE EXTENSION jsonvd" to load this file. \quit

-------------------------------------------------------------------------------
-- Version
-------------------------------------------------------------------------------

CREATE FUNCTION @extschema@.version()
RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE
AS $$ SELECT '1.0.0'::text $$;

COMMENT ON FUNCTION @extschema@.version() IS
'Version of the jsonvd library.';

-------------------------------------------------------------------------------
-- Value inference from text
-------------------------------------------------------------------------------

-- Converts text into the JSON value it represents:
--   'null' -> null, 'true'/'false' -> boolean, '12' / '-1.5e3' -> number,
--   valid '{...}' / '[...]' / '"..."' -> that JSON, anything else -> string.
-- Numbers follow the JSON grammar: '007' or '1.' stay strings.
CREATE FUNCTION @extschema@.parse_value(txt text)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
	t text := btrim(txt);
BEGIN
	IF t IN ('null', 'true', 'false')
	   OR t ~ '^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$'
	   OR left(t, 1) IN ('{', '[', '"') THEN
		BEGIN
			RETURN t::jsonb;
		EXCEPTION WHEN data_exception THEN
			NULL; -- not valid JSON: treat it as a string
		END;
	END IF;

	RETURN to_jsonb(txt);
END;
$$;

COMMENT ON FUNCTION @extschema@.parse_value(text) IS
'Converts text into its JSON value (null, boolean, number, object, array or string).';

CREATE FUNCTION @extschema@.typeof_text(txt text)
RETURNS text
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT jsonb_typeof(@extschema@.parse_value(txt)) $$;

COMMENT ON FUNCTION @extschema@.typeof_text(text) IS
'JSON type (null, boolean, number, string, object, array) represented by a text.';

-------------------------------------------------------------------------------
-- Building
-------------------------------------------------------------------------------

-- build_object('id', '15', 'active', 'true', 'tags', '["a"]')
--   -> {"id": 15, "tags": ["a"], "active": true}
CREATE FUNCTION @extschema@.build_object(VARIADIC pairs text[])
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
	result jsonb := '{}';
	i integer;
BEGIN
	IF coalesce(array_length(pairs, 1), 0) % 2 <> 0 THEN
		RAISE EXCEPTION 'jsonvd.build_object: expected key/value pairs, got % arguments',
			array_length(pairs, 1)
			USING ERRCODE = 'invalid_parameter_value';
	END IF;

	FOR i IN 1 .. coalesce(array_length(pairs, 1), 0) BY 2 LOOP
		IF pairs[i] IS NULL THEN
			RAISE EXCEPTION 'jsonvd.build_object: key of pair % is NULL', (i + 1) / 2
				USING ERRCODE = 'null_value_not_allowed';
		END IF;
		result := result || jsonb_build_object(
			pairs[i],
			coalesce(@extschema@.parse_value(pairs[i + 1]), 'null'::jsonb));
	END LOOP;

	RETURN result;
END;
$$;

COMMENT ON FUNCTION @extschema@.build_object(text[]) IS
'Builds an object from text key/value pairs, inferring the type of each value.';

-------------------------------------------------------------------------------
-- Modification
-------------------------------------------------------------------------------

CREATE FUNCTION @extschema@.push(doc jsonb, key text, value jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
	IF jsonb_typeof(doc) <> 'object' THEN
		RAISE EXCEPTION 'jsonvd.push: a key can only be added to an object, got %',
			jsonb_typeof(doc)
			USING ERRCODE = 'invalid_parameter_value';
	END IF;

	RETURN doc || jsonb_build_object(key, value);
END;
$$;

COMMENT ON FUNCTION @extschema@.push(jsonb, text, jsonb) IS
'Adds (or replaces) a key in an object.';

CREATE FUNCTION @extschema@.push(doc jsonb, key text, value text)
RETURNS jsonb
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$ SELECT @extschema@.push(doc, key, @extschema@.parse_value(value)) $$;

COMMENT ON FUNCTION @extschema@.push(jsonb, text, text) IS
'Adds (or replaces) a key in an object, inferring the value type from text.';

-- Like jsonb_set, but creates any missing intermediate objects.
--   set_path('{}', '{a,b,c}', '1') -> {"a": {"b": {"c": 1}}}
CREATE FUNCTION @extschema@.set_path(doc jsonb, path text[], value jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
	result jsonb := doc;
	node jsonb;
	i integer;
BEGIN
	IF cardinality(path) = 0 THEN
		RETURN value;
	END IF;

	FOR i IN 1 .. cardinality(path) - 1 LOOP
		node := result #> path[1:i];
		IF node IS NULL OR node = 'null'::jsonb THEN
			result := jsonb_set(result, path[1:i], '{}'::jsonb, true);
		ELSIF jsonb_typeof(node) NOT IN ('object', 'array') THEN
			RAISE EXCEPTION 'jsonvd.set_path: % is a %, cannot descend into it',
				path[1:i], jsonb_typeof(node)
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END LOOP;

	RETURN jsonb_set(result, path, value, true);
END;
$$;

COMMENT ON FUNCTION @extschema@.set_path(jsonb, text[], jsonb) IS
'Like jsonb_set, but creates any missing intermediate objects.';

CREATE FUNCTION @extschema@.delete_key_deep(doc jsonb, key text)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
BEGIN
	CASE jsonb_typeof(doc)
	WHEN 'object' THEN
		RETURN coalesce(
			(SELECT jsonb_object_agg(e.key, @extschema@.delete_key_deep(e.value, delete_key_deep.key))
			 FROM jsonb_each(doc) AS e
			 WHERE e.key <> delete_key_deep.key),
			'{}'::jsonb);
	WHEN 'array' THEN
		RETURN coalesce(
			(SELECT jsonb_agg(@extschema@.delete_key_deep(a.value, delete_key_deep.key) ORDER BY a.ord)
			 FROM jsonb_array_elements(doc) WITH ORDINALITY AS a(value, ord)),
			'[]'::jsonb);
	ELSE
		RETURN doc;
	END CASE;
END;
$$;

COMMENT ON FUNCTION @extschema@.delete_key_deep(jsonb, text) IS
'Removes a key at every level of the document.';

-------------------------------------------------------------------------------
-- Merge
-------------------------------------------------------------------------------

-- Recursive merge: objects are merged key by key; in any other case
-- (arrays, scalars, mismatched types) b wins. PostgreSQL's || operator
-- only merges the top level.
CREATE FUNCTION @extschema@.merge_deep(a jsonb, b jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $$
BEGIN
	IF a IS NULL THEN RETURN b; END IF;
	IF b IS NULL THEN RETURN a; END IF;
	IF jsonb_typeof(a) <> 'object' OR jsonb_typeof(b) <> 'object' THEN
		RETURN b;
	END IF;

	RETURN coalesce(
		(SELECT jsonb_object_agg(k.key, @extschema@.merge_deep(a -> k.key, b -> k.key))
		 FROM (SELECT jsonb_object_keys(a) UNION SELECT jsonb_object_keys(b)) AS k(key)),
		'{}'::jsonb);
END;
$$;

COMMENT ON FUNCTION @extschema@.merge_deep(jsonb, jsonb) IS
'Recursive object merge; on any conflict other than object/object, b wins.';

-- JSON Merge Patch (RFC 7396): like merge_deep, but a null in the patch
-- removes the key.
CREATE FUNCTION @extschema@.merge_patch(target jsonb, patch jsonb)
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $$
DECLARE
	result jsonb := target;
	k text;
	v jsonb;
BEGIN
	IF patch IS NULL THEN RETURN target; END IF;
	IF jsonb_typeof(patch) <> 'object' THEN RETURN patch; END IF;
	IF result IS NULL OR jsonb_typeof(result) <> 'object' THEN
		result := '{}';
	END IF;

	FOR k, v IN SELECT e.key, e.value FROM jsonb_each(patch) AS e LOOP
		IF v = 'null'::jsonb THEN
			result := result - k;
		ELSE
			result := jsonb_set(result, ARRAY[k], @extschema@.merge_patch(result -> k, v), true);
		END IF;
	END LOOP;

	RETURN result;
END;
$$;

COMMENT ON FUNCTION @extschema@.merge_patch(jsonb, jsonb) IS
'Applies a JSON Merge Patch (RFC 7396).';

-------------------------------------------------------------------------------
-- Traversal and search
-------------------------------------------------------------------------------

-- Every node of the document (root included). ord sorts nodes in document
-- order (pre-order). Internal use.
CREATE FUNCTION @extschema@._nodes(doc jsonb)
RETURNS TABLE (path text[], ord bigint[], value jsonb)
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	WITH RECURSIVE node(path, ord, value) AS (
		SELECT '{}'::text[], '{}'::bigint[], doc
		UNION ALL
		SELECT n.path || c.k, n.ord || c.o, c.v
		FROM node AS n
		CROSS JOIN LATERAL (
			SELECT e.key, e.o, e.value
			FROM jsonb_each(CASE WHEN jsonb_typeof(n.value) = 'object' THEN n.value ELSE '{}' END)
				WITH ORDINALITY AS e(key, value, o)
			UNION ALL
			SELECT (a.o - 1)::text, a.o, a.value
			FROM jsonb_array_elements(CASE WHEN jsonb_typeof(n.value) = 'array' THEN n.value ELSE '[]' END)
				WITH ORDINALITY AS a(value, o)
		) AS c(k, o, v)
	)
	SELECT path, ord, value FROM node
$$;

-- Flattens the document: one row per node, in document order.
-- Note: jsonb does not preserve the original key order of an object.
CREATE FUNCTION @extschema@.flatten(doc jsonb)
RETURNS TABLE (path text[], value jsonb, type text, depth integer)
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT n.path, n.value, jsonb_typeof(n.value), cardinality(n.path)
	FROM @extschema@._nodes(doc) AS n
	ORDER BY n.ord
$$;

COMMENT ON FUNCTION @extschema@.flatten(jsonb) IS
'One row per node of the document: path, value, type and depth.';

CREATE FUNCTION @extschema@.find_paths(doc jsonb, target jsonb)
RETURNS SETOF text[]
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT n.path
	FROM @extschema@._nodes(doc) AS n
	WHERE n.value = target
	ORDER BY n.ord
$$;

COMMENT ON FUNCTION @extschema@.find_paths(jsonb, jsonb) IS
'Every path (text[]) where target appears, in document order.';

CREATE FUNCTION @extschema@.find_path(doc jsonb, target jsonb)
RETURNS text[]
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT n.path
	FROM @extschema@._nodes(doc) AS n
	WHERE n.value = target
	ORDER BY n.ord
	LIMIT 1
$$;

COMMENT ON FUNCTION @extschema@.find_path(jsonb, jsonb) IS
'First path (text[]) where target appears, or NULL. Works with #> and jsonb_set.';

CREATE FUNCTION @extschema@.contains_deep(doc jsonb, target jsonb)
RETURNS boolean
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT EXISTS (SELECT 1 FROM @extschema@._nodes(doc) AS n WHERE n.value = target)
$$;

COMMENT ON FUNCTION @extschema@.contains_deep(jsonb, jsonb) IS
'true if target appears as a value at any level of the document.';

-------------------------------------------------------------------------------
-- Diff
-------------------------------------------------------------------------------

-- Differences between two documents, using JSON Patch vocabulary
-- (add / remove / replace). Arrays are compared by position.
CREATE FUNCTION @extschema@.diff(a jsonb, b jsonb)
RETURNS TABLE (path text[], op text, old_value jsonb, new_value jsonb)
LANGUAGE sql IMMUTABLE PARALLEL SAFE
AS $$
	WITH RECURSIVE pair(path, ord, l, r) AS (
		SELECT '{}'::text[], '{}'::bigint[], a, b
		UNION ALL
		SELECT p.path || c.k, p.ord || c.o, c.l, c.r
		FROM pair AS p
		CROSS JOIN LATERAL (
			SELECT
				coalesce(jsonb_typeof(p.l) = 'object' AND jsonb_typeof(p.r) = 'object', false),
				coalesce(jsonb_typeof(p.l) = 'array' AND jsonb_typeof(p.r) = 'array', false)
		) AS kind(both_objects, both_arrays)
		CROSS JOIN LATERAL (
			SELECT u.key, row_number() OVER (ORDER BY u.key), p.l -> u.key, p.r -> u.key
			FROM (
				SELECT jsonb_object_keys(CASE WHEN both_objects THEN p.l ELSE '{}' END)
				UNION
				SELECT jsonb_object_keys(CASE WHEN both_objects THEN p.r ELSE '{}' END)
			) AS u(key)
			UNION ALL
			SELECT i::text, i + 1, p.l -> i, p.r -> i
			FROM generate_series(
				0,
				CASE WHEN both_arrays
					THEN greatest(jsonb_array_length(p.l), jsonb_array_length(p.r)) - 1
					ELSE -1
				END) AS i
		) AS c(k, o, l, r)
		WHERE p.l IS DISTINCT FROM p.r
	)
	SELECT
		path,
		CASE WHEN l IS NULL THEN 'add' WHEN r IS NULL THEN 'remove' ELSE 'replace' END,
		l,
		r
	FROM pair
	WHERE l IS DISTINCT FROM r
	  AND NOT coalesce(jsonb_typeof(l) = 'object' AND jsonb_typeof(r) = 'object', false)
	  AND NOT coalesce(jsonb_typeof(l) = 'array' AND jsonb_typeof(r) = 'array', false)
	ORDER BY ord
$$;

COMMENT ON FUNCTION @extschema@.diff(jsonb, jsonb) IS
'Differences between two documents: path, operation (add/remove/replace), old and new value.';

-------------------------------------------------------------------------------
-- Schema inference
-------------------------------------------------------------------------------

-- Suggested PostgreSQL type for each key of an array of objects.
CREATE FUNCTION @extschema@.infer_schema(rows jsonb)
RETURNS TABLE (key text, pg_type text)
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	WITH field AS (
		SELECT e.key, e.value, jsonb_typeof(e.value) AS t, ARRAY[r.o, e.o] AS ord
		FROM jsonb_array_elements(rows) WITH ORDINALITY AS r(elem, o)
		CROSS JOIN LATERAL jsonb_each(CASE WHEN jsonb_typeof(r.elem) = 'object' THEN r.elem ELSE '{}' END)
			WITH ORDINALITY AS e(key, value, o)
	)
	SELECT
		key,
		CASE
			WHEN bool_and(t = 'null') THEN 'text'
			WHEN bool_and(t IN ('number', 'null')) THEN
				CASE WHEN bool_and(t = 'null' OR value::text ~ '^-?[0-9]{1,18}$') THEN 'bigint' ELSE 'numeric' END
			WHEN bool_and(t IN ('boolean', 'null')) THEN 'boolean'
			WHEN bool_and(t IN ('string', 'null')) THEN
				CASE
					WHEN bool_and(t = 'null' OR value #>> '{}' ~ '^\d{4}-\d{2}-\d{2}$') THEN 'date'
					WHEN bool_and(t = 'null' OR value #>> '{}' ~ '^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?$') THEN 'timestamp'
					WHEN bool_and(t = 'null' OR value #>> '{}' ~ '^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}(:?\d{2})?)$') THEN 'timestamptz'
					ELSE 'text'
				END
			ELSE 'jsonb'
		END
	FROM field
	GROUP BY key
	ORDER BY min(ord)
$$;

COMMENT ON FUNCTION @extschema@.infer_schema(jsonb) IS
'Suggested PostgreSQL type for each key of an array of objects.';

-- Column list ready for jsonb_to_recordset(...) AS t(<here>).
CREATE FUNCTION @extschema@.recordset_definition(rows jsonb)
RETURNS text
LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
AS $$
	SELECT string_agg(format('%I %s', s.key, s.pg_type), ', ' ORDER BY s.n)
	FROM @extschema@.infer_schema(rows) WITH ORDINALITY AS s(key, pg_type, n)
$$;

COMMENT ON FUNCTION @extschema@.recordset_definition(jsonb) IS
'Inferred column definition list for use with jsonb_to_recordset.';

-------------------------------------------------------------------------------
-- Legacy path format: [{"clave": "...", "posicion": n}, ...]
-- ("clave" = key, "posicion" = position; kept as-is for compatibility)
-------------------------------------------------------------------------------

-- Rules of the original procedures (return_jsonVD, add_position_jsonVD, ...):
--   * For each step, if the current node is an array, "posicion" is taken
--     (0 if missing and the step has a "clave"); then, if there is a "clave",
--     the path enters it.
--   * The "clave" of the LAST step is not entered: it names the key that will
--     be read or written in the object the path points to.
--   * An empty step {} does nothing.
CREATE FUNCTION @extschema@.legacy_path(doc jsonb, steps jsonb)
RETURNS text[]
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
	cur jsonb := doc;
	step jsonb;
	n bigint;
	total integer;
	pos integer;
	result text[] := '{}';
BEGIN
	IF jsonb_typeof(steps) <> 'array' THEN
		RAISE EXCEPTION 'jsonvd.legacy_path: expected an array of {"clave", "posicion"} steps, got %',
			jsonb_typeof(steps)
			USING ERRCODE = 'invalid_parameter_value';
	END IF;

	total := jsonb_array_length(steps);

	FOR step, n IN SELECT s.value, s.ord FROM jsonb_array_elements(steps) WITH ORDINALITY AS s(value, ord) LOOP
		IF jsonb_typeof(cur) = 'array' AND (step ? 'posicion' OR step ? 'clave') THEN
			pos := coalesce((step ->> 'posicion')::integer, 0);
			result := result || pos::text;
			cur := cur -> pos;
		END IF;

		IF n < total AND jsonb_typeof(step -> 'clave') = 'string' THEN
			result := result || (step ->> 'clave');
			cur := cur -> (step ->> 'clave');
		END IF;
	END LOOP;

	RETURN result;
END;
$$;

COMMENT ON FUNCTION @extschema@.legacy_path(jsonb, jsonb) IS
'Converts a legacy [{"clave","posicion"}] path into text[] for use with #> and jsonb_set.';

CREATE FUNCTION @extschema@.to_legacy_path(doc jsonb, path text[])
RETURNS jsonb
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
AS $$
DECLARE
	cur jsonb := doc;
	steps jsonb := '[]';
	n integer := cardinality(path);
	i integer := 1;
	pos integer;
BEGIN
	WHILE i <= n LOOP
		CASE jsonb_typeof(cur)
		WHEN 'array' THEN
			pos := path[i]::integer;
			cur := cur -> pos;
			i := i + 1;
			IF i <= n AND jsonb_typeof(cur) = 'object' THEN
				steps := steps || jsonb_build_object('clave', path[i], 'posicion', pos);
				cur := cur -> path[i];
				i := i + 1;
			ELSE
				steps := steps || jsonb_build_object('posicion', pos);
			END IF;
		WHEN 'object' THEN
			steps := steps || jsonb_build_object('clave', path[i], 'posicion', 0);
			cur := cur -> path[i];
			i := i + 1;
		ELSE
			RAISE EXCEPTION 'jsonvd.to_legacy_path: path % does not exist in the document', path
				USING ERRCODE = 'invalid_parameter_value';
		END CASE;
	END LOOP;

	-- The "clave" of the last step is not entered (see legacy_path): if the
	-- path ends by entering a key, close it with an empty step.
	IF steps -> -1 ? 'clave' THEN
		steps := steps || '[{}]'::jsonb;
	END IF;

	RETURN steps;
END;
$$;

COMMENT ON FUNCTION @extschema@.to_legacy_path(jsonb, text[]) IS
'Converts a text[] path into the legacy [{"clave","posicion"}] format.';
