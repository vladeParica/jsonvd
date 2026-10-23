\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

SELECT jsonvd.build_object('id', '15', 'name', 'O''Brien', 'active', 'true',
                           'tags', '["a","b"]', 'meta', '{"x":1}', 'empty', 'null');

SELECT jsonvd.build_object(VARIADIC '{}'::text[]) AS empty;

-- A SQL NULL value is stored as JSON null
SELECT jsonvd.build_object('a', NULL);

-- Errors: odd number of arguments and NULL key
SELECT jsonvd.build_object('a', '1', 'b');
SELECT jsonvd.build_object(NULL, '1');
