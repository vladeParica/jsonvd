\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

-- push with text: infers the type and keeps the key's case
SELECT jsonvd.push('{"a":1}', 'Prueba', '1')      AS number,
       jsonvd.push('{"a":1}', 'k', 'false')       AS boolean,
       jsonvd.push('{"a":1}', 'k', 'hello')       AS string,
       jsonvd.push('{"a":1}', 'k', '[1,2]')       AS array;

-- push with explicit jsonb
SELECT jsonvd.push('{"a":1}', 'k', '"1"'::jsonb) AS explicit_string;

-- push replaces an existing key; quotes in values break nothing
SELECT jsonvd.push('{"name":"O''Brien","a":1}', 'a', 'it''s "quoted"');

-- push only works on objects
SELECT jsonvd.push('[1,2]', 'k', '1');

-- set_path creates the intermediate objects
SELECT jsonvd.set_path('{}', '{a,b,c}', '1');
SELECT jsonvd.set_path('{"a":{"x":1}}', '{a,b}', '"new"');
SELECT jsonvd.set_path('{"a":null}', '{a,b}', 'true');
SELECT jsonvd.set_path('{"list":[{"x":1},{"x":2}]}', '{list,1,y}', '3');
SELECT jsonvd.set_path('{"a":1}', '{}', '"root"');
-- cannot descend into a scalar
SELECT jsonvd.set_path('{"a":1}', '{a,b}', '2');

-- delete_key_deep removes the key at every level
SELECT jsonvd.delete_key_deep(
	'{"id":1,"password":"x","user":{"password":"y","roles":[{"password":"z","name":"admin"}]},"empty":{"password":1}}',
	'password');
SELECT jsonvd.delete_key_deep('[]', 'a'), jsonvd.delete_key_deep('5', 'a');
