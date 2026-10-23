\set VERBOSITY terse
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS jsonvd;

CREATE TEMP TABLE doc AS SELECT
'{"tramites":[
	{"title":"Actualización","id":23,"tipos":null},
	{"title":"Certificación","id":38,"tipos":[
		{"idTipo":367,"licencia":"Instructor de Vuelo Avión","categorias":[{"idCategoria":2,"categoria":"Avión"}]},
		{"idTipo":510,"licencia":"Instructor de Vuelo de Planeador","categorias":[{"idCategoria":7,"categoria":"Planeador"}]},
		{"idTipo":361,"licencia":"Piloto Privado - Avión","categorias":[{"idCategoria":2,"categoria":"Avión"}]}
	]},
	{"title":"Duplicado de Licencia","id":17,"tipos":null}
]}'::jsonb AS d;

-- flatten: one row per node, in document order
SELECT path, type, depth, CASE WHEN type IN ('object','array') THEN '...' ELSE value::text END AS value
FROM jsonvd.flatten('{"a":1,"b":[true,{"c":null}],"d":{}}');

-- find_path returns a path that works directly with #>
SELECT jsonvd.find_path(d, '{"idCategoria":7,"categoria":"Planeador"}') AS path,
       d #> jsonvd.find_path(d, '{"idCategoria":7,"categoria":"Planeador"}') AS value
FROM doc;

-- key order and whitespace do not matter (jsonb equality)
SELECT jsonvd.find_path(d, '{ "id" : 17,  "tipos": null, "title":"Duplicado de Licencia" }') FROM doc;

-- find_paths: every occurrence
SELECT jsonvd.find_paths(d, '{"idCategoria":2,"categoria":"Avión"}') FROM doc;
SELECT jsonvd.find_paths(d, 'null') FROM doc;

-- not found
SELECT jsonvd.find_path(d, '{"no":"match"}') IS NULL AS not_found FROM doc;

-- contains_deep
SELECT jsonvd.contains_deep(d, '"Planeador"')                            AS scalar,
       jsonvd.contains_deep(d, '[{"idCategoria":2,"categoria":"Avión"}]') AS array,
       jsonvd.contains_deep(d, '{"idCategoria":2}')                      AS partial,
       jsonvd.contains_deep(d, d)                                        AS root
FROM doc;

-- strings with spaces are no longer confused (bug in the original procedures)
SELECT jsonvd.contains_deep('{"a":"Avión Comercial"}', '"AviónComercial"') AS spaces;

-- find and modify
SELECT jsonb_set(d, jsonvd.find_path(d, '"Piloto Privado - Avión"'), '"Piloto Privado"')
       #> '{tramites,1,tipos,2,licencia}' AS updated
FROM doc;
