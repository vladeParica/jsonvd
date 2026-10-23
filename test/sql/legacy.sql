\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

CREATE TEMP TABLE songs AS SELECT
'[{"song":"Somebody told me","banda":"The killers"},
  {"song":"Miss Atomic Bomb","banda":"The killers"},
  {"song":"Fix you","banda":"Coldplay",
   "nodo_maluma":[{"song":"Tu me partiste el corazon","banda":"maluma"},{"song":"mientes","banda":"camila"}],
   "solista":{"song":"Let me","cantante":"zayn"}}]'::jsonb AS d;

-- The key of the last step is not entered (same as the original procedures)
SELECT steps, jsonvd.legacy_path(d, steps::jsonb) AS path, d #> jsonvd.legacy_path(d, steps::jsonb) AS value
FROM songs, (VALUES
	('[{"clave":"nodo_maluma","posicion":2},{"posicion":1}]'),
	('[{"clave":"nodo_maluma","posicion":2}]'),
	('[{"clave":"solista","posicion":2},{}]'),
	('[{"posicion":0}]'),
	('[]')
) AS s(steps);

-- object root: "posicion" is ignored while the node is not an array
SELECT jsonvd.legacy_path(
	'{"id":367,"categorias":[{"idCategoria":2,"otro_nodo":{"tu_tia":"ana maria"}}]}',
	'[{"clave":"categorias","posicion":1},{"clave":"otro_nodo","posicion":0}]');

-- round trip: to_legacy_path -> legacy_path returns the same path
SELECT p.path, jsonvd.to_legacy_path(d, p.path) AS steps,
       jsonvd.legacy_path(d, jsonvd.to_legacy_path(d, p.path)) = p.path AS roundtrip
FROM songs, LATERAL jsonvd.flatten(d) AS p
WHERE p.depth BETWEEN 1 AND 4 AND p.type IN ('object', 'array', 'string')
ORDER BY p.path
LIMIT 12;

SELECT bool_and(jsonvd.legacy_path(d, jsonvd.to_legacy_path(d, p.path)) = p.path) AS all_roundtrip
FROM songs, LATERAL jsonvd.flatten(d) AS p;

-- errors
SELECT jsonvd.legacy_path('[1]', '{"clave":"x"}');
SELECT jsonvd.to_legacy_path('{"a":1}', '{a,b}');
