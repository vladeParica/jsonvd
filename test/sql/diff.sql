\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

SELECT * FROM jsonvd.diff(
	'{"a":1,"b":[1,2,3],"c":{"x":1},"same":{"deep":[1,2]},"t":"x"}',
	'{"a":2,"b":[1,5],"c":{"y":1},"same":{"deep":[1,2]},"t":["x"],"d":null}');

-- equal documents: no rows (even with different key order or whitespace)
SELECT count(*) AS changes FROM jsonvd.diff('{"a":1, "b":[1,2]}', '{ "b" : [1,2], "a" : 1 }');

-- cases the original compare_jsonVD reported as equal
SELECT count(*) AS changes_11_vs_22 FROM jsonvd.diff('[1,1]', '[2,2]');
SELECT count(*) AS changes_obj_vs_arr FROM jsonvd.diff('{"a":1}', '[1]');

-- root added or removed
SELECT * FROM jsonvd.diff(NULL, '{"a":1}');
SELECT * FROM jsonvd.diff('{"a":1}', NULL);

-- array indexes are ordered numerically
SELECT path, op FROM jsonvd.diff('[0,1,2,3,4,5,6,7,8,9,10,11]', '[0,1,2,3,4,5,6,7,8,9,10,11,12]');
SELECT path, op FROM jsonvd.diff('[0,1,2,3,4,5,6,7,8,9,10,11]', '[0,1,"x",3,4,5,6,7,8,9,10,"y"]');
