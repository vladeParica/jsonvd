\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

-- merge_deep merges nested objects; || only merges the top level
SELECT '{"db":{"host":"localhost","port":5432},"debug":false}'::jsonb
    || '{"db":{"port":6543},"debug":true}'::jsonb AS native_operator;

SELECT jsonvd.merge_deep(
	'{"db":{"host":"localhost","port":5432},"debug":false,"tags":[1,2]}',
	'{"db":{"port":6543,"ssl":{"mode":"require"}},"debug":true,"tags":[3]}');

-- on a non object/object conflict b wins; JSON null wins too
SELECT jsonvd.merge_deep('{"a":{"x":1}}', '{"a":5}'),
       jsonvd.merge_deep('{"a":1}', '{"a":null}'),
       jsonvd.merge_deep('[1]', '{"a":1}');

-- SQL NULL is ignored
SELECT jsonvd.merge_deep(NULL, '{"a":1}'), jsonvd.merge_deep('{"a":1}', NULL);

-- merge_patch (RFC 7396): null removes the key
SELECT jsonvd.merge_patch(
	'{"title":"Goodbye!","author":{"givenName":"John","familyName":"Doe"},"tags":["example","sample"],"content":"This will be unchanged"}',
	'{"title":"Hello!","phoneNumber":"+01-123-456-7890","author":{"familyName":null},"tags":["example"]}');

-- RFC 7396 appendix A test cases
SELECT t AS target, p AS patch, jsonvd.merge_patch(t, p) AS result
FROM (VALUES
	('{"a":"b"}'::jsonb,      '{"a":"c"}'::jsonb),
	('{"a":"b"}',             '{"b":"c"}'),
	('{"a":"b"}',             '{"a":null}'),
	('{"a":"b","b":"c"}',     '{"a":null}'),
	('{"a":["b"]}',           '{"a":"c"}'),
	('{"a":"c"}',             '{"a":["b"]}'),
	('{"a":{"b":"c"}}',       '{"a":{"b":"d","c":null}}'),
	('{"a":[{"b":"c"}]}',     '{"a":[1]}'),
	('["a","b"]',             '["c","d"]'),
	('{"a":"b"}',             '["c"]'),
	('{"a":"foo"}',           'null'),
	('{"a":"foo"}',           '"bar"'),
	('{"e":null}',            '{"a":1}'),
	('[1,2]',                 '{"a":"b","c":null}'),
	('{}',                    '{"a":{"bb":{"ccc":null}}}')
) AS c(t, p);
