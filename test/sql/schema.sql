\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

CREATE TEMP TABLE rows AS SELECT
'[{"id":1,"name":"Vlade","active":true,"balance":10.5,"born":"1990-01-02","created":"2024-01-01T10:00:00Z","tags":["a"],"note":null,"mixed":1},
  {"id":2,"name":"Dey","active":false,"balance":3,"born":null,"created":"2024-02-01 08:30:00+02","tags":[],"note":null,"mixed":"x","extra":"only here"},
  {"id":99999999999,"name":"O''Brien","balance":null,"created":"2024-03-01T00:00:00-05:00","local":"2024-03-01T00:00:00"}]'::jsonb AS r;

SELECT * FROM jsonvd.infer_schema((SELECT r FROM rows));

SELECT jsonvd.recordset_definition(r) FROM rows;

-- keys that are not plain identifiers get quoted
SELECT jsonvd.recordset_definition('[{"Full Name":"x","select":1}]');

-- typical use: build the typed query
SELECT format('SELECT * FROM jsonb_to_recordset(%L) AS t(%s)', r, jsonvd.recordset_definition(r)) AS q
FROM rows \gset
SELECT id, name, active, balance, born, extra FROM (:q) AS t ORDER BY id;

-- empty array or no objects
SELECT count(*) FROM jsonvd.infer_schema('[]');
SELECT jsonvd.recordset_definition('[1,2]') IS NULL AS no_columns;
