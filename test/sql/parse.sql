\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

-- parse_value: each text yields the JSON value it represents
SELECT v AS input, jsonvd.parse_value(v) AS value, jsonvd.typeof_text(v) AS type
FROM unnest(ARRAY[
	'null', 'true', 'false', '0', '1', '-12', '1.5', '2e3', '-0.5E-2',
	'{"a":1}', '[1,"x"]', '"quoted"', 'hello', 'O''Brien', '007', '1.', '{broken',
	'2018-05-11', 'TRUE', '  42  ', ''
]) AS v;

-- A number too large for numeric is returned as a string, not an error
SELECT jsonvd.parse_value('1e1000000') AS overflow, jsonvd.typeof_text('1e1000000') AS overflow_type;

-- SQL NULL in, SQL NULL out
SELECT jsonvd.parse_value(NULL) IS NULL AS strict_null;
