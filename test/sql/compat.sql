\set VERBOSITY terse
SET client_min_messages = warning;
\set ECHO none
\i compat/jsonvd_legacy.sql
\set ECHO all

-- Bugs of the original procedures, now fixed
SELECT json_push_vd('{"a":1}', 'Prueba', '1')   AS one,
       json_push_vd('{"a":1}', 'k', '0')        AS zero,
       json_push_vd('{"a":1}', 'k', 'false')    AS false_value;
SELECT json_push_vd('[]', 'k', '5')                      AS empty_array,
       json_push_vd('{"name":"O''Brien"}', 'k', '5')    AS apostrophe;

SELECT json_pushVD('{"a":1}', '"b"', 2), json_pushVD('{"a":1}', '"b"', true), json_pushVD('{"a":1}', '"b"', 'hello'::varchar);

SELECT compare_jsonVD('[1,1]', '[2,2]')                                         AS a,
       compare_jsonVD('{"a":1}', '[1]')                                         AS b,
       compare_jsonVD('{"a":"Avión Comercial"}', '{"a":"AviónComercial"}')      AS c,
       compare_jsonVD('{"a":1, "b":[1,{"c":2}]}', '{"b":[1,{"c":2}], "a":1}')    AS d;

SELECT typeof_vd('null'), typeof_vd('yes'), typeof_vd('1.5'), typeof_vd('7'),
       typeof_vd('true'), typeof_vd('{}'), typeof_vd('2018-05-11'), typeof_vd('hello');

SELECT to_json_build_vd('k', 'yes', 'n', '15', 'b', 'true', 'arr', '[]', 'nulls', 'null');
SELECT json_agg_build_vd('k', 'v');

SELECT convert_array_jsonVD('{"tag":"#1"}#{"b":2}');
SELECT convert_array_jsonVD('{"a":1}#[1]');
-- invalid JSON: the error names the element, never its content
SELECT convert_array_jsonVD('{"a":1}#{"password":"s3cret"');

SELECT json_deleteVD('{"name":"O''Brien","x":1}', 'x');
SELECT json_deleteVD('{"name":"O''Brien","x":1}', '"name"');
SELECT json_deleteVD('[{"a":1,"b":2},{"a":3,"b":4}]', 'b', 1);
SELECT json_deleteVD('[1,2]', 'b', 0);

SELECT valid_json_positionVD('[{"clave":"nullable","posicion":1},{"posicion":null}]');

SELECT probando_locura('[{"a":1,"b":"x"},{"a":2.5,"c":true}]');

-- Reading by legacy path
SELECT return_jsonVD(d, '[{"clave":"nodo_maluma","posicion":2},{"posicion":4}]') AS missing,
       return_jsonVD(d, '[{"clave":"nodo_maluma","posicion":2},{"posicion":1}]') AS found,
       return_json_valueVD(d, '[{"clave":"nodo_maluma","posicion":2},{"posicion":1}]', 'song') AS value,
       return_json_valueVD(d, '[{"clave":"nodo_maluma","posicion":2}]', 'no_key') AS missing_key,
       return_json_valueVD(d, '[{"clave":"nodo_maluma","posicion":2},{}]', 'song') AS is_array
FROM (SELECT '[{"song":"a"},{"song":"b"},{"song":"c","nodo_maluma":[{"song":"x"},{"song":"y"}]}]'::json AS d) AS s;

-- Adding at a legacy path (the original add_position_jsonVD example)
SELECT add_position_jsonVD(
	'[{"x": 45, "demenecia": 458 }, {"y": 78, "locura": 458 }, {"ezz": {"z": 15, "desquiciado": 357, "nodo_pro": [{"jarvis": "locote"}, {"normal": 45 }] } }]',
	'[{"clave": "ezz", "posicion": 2}, {"clave": "nodo_pro", "posicion": 0}, {"posicion": 1}]',
	'prueba',
	'{"prueba":1 ,"rawayana":"sin ti"}');

-- Searching: search_positionVD returns a path that return_jsonVD can read
SELECT search_jsonVD(d, '{"song":"y"}')            AS found,
       search_jsonVD(d, '[{"song":"y"}]')          AS found_in_array,
       search_jsonVD(d, '{"song":"zzz"}')          AS not_found,
       search_positionVD(d, '{"song":"y"}')        AS path,
       return_jsonVD(d, search_positionVD(d, '{"song":"y"}')::json) AS round_trip,
       search_positionVD(d, '{"song":"zzz"}')      AS path_not_found
FROM (SELECT '[{"song":"a"},{"song":"b"},{"song":"c","nodo_maluma":[{"song":"x"},{"song":"y"}]}]'::json AS d) AS s;

SELECT search_positionVD('{"id": 367, "categorias": [{"idCategoria": 2, "categoria": "Avión"}]}',
                         '[{"idCategoria": 2, "categoria": "Avión"}]');
