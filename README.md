<p align="center"><img src="Logo/logoExtensionPostgresql.png" alt="jsonvd" width="220"></p>

# jsonvd

[![CI](https://github.com/vladeParica/jsonvd/actions/workflows/ci.yml/badge.svg)](https://github.com/vladeParica/jsonvd/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A PostgreSQL extension with JSONB utilities the engine does not ship with:
**find the path of a value**, **diff** two documents, **deep merge** and
**JSON Merge Patch**, **infer types and schemas** from JSON, plus a compatibility
layer for the original `*VD` procedures ([`legacy/`](legacy/)).

- Pure SQL / PL/pgSQL: nothing to compile.
- PostgreSQL **14 to 18** (tested in CI).
- No dynamic SQL: values are never concatenated into executable text.
- `IMMUTABLE PARALLEL SAFE` functions: usable in expression indexes and parallel queries.

## Installation

```bash
git clone https://github.com/vladeParica/jsonvd
cd jsonvd
make install          # needs pg_config on PATH (postgresql-server-dev-XX package)
```

```sql
CREATE EXTENSION jsonvd;   -- creates the jsonvd schema
```

The extension is `trusted`: a user with `CREATE` privilege on the database can install it without being a superuser.

**Without server access** (e.g. RDS, Cloud SQL): run `CREATE SCHEMA jsonvd;`, then the contents
of `sql/jsonvd--1.0.0.sql` with `@extschema@` replaced by `jsonvd` and the `\echo ... \quit` line removed.

## API

Every function lives in the `jsonvd` schema.

### Path search

PostgreSQL can read a value given a path (`#>`), but it cannot tell you **where** a value is.

| Function | Returns |
|---|---|
| `find_path(doc, target)` | First `text[]` path where `target` appears, or `NULL` |
| `find_paths(doc, target)` | Every path, in document order |
| `contains_deep(doc, target)` | `true` if `target` appears at any level |
| `flatten(doc)` | One row per node: `path`, `value`, `type`, `depth` |

```sql
SELECT jsonvd.find_path(doc, '{"idCategoria": 7, "categoria": "Planeador"}');
--  {tramites,1,tipos,1,categorias,0}

-- The path works directly with the native operators
UPDATE tramites
SET    doc = jsonb_set(doc, jsonvd.find_path(doc, '"Piloto Privado - Avión"'), '"Piloto Privado"')
WHERE  jsonvd.contains_deep(doc, '"Piloto Privado - Avión"');
```

Matching uses `jsonb` equality: whitespace and key order do not matter.

### Diff

```sql
SELECT * FROM jsonvd.diff('{"a":1,"b":[1,2,3],"c":{"x":1}}',
                          '{"a":2,"b":[1,5],"c":{"y":1},"d":null}');
```
```
 path  |   op    | old_value | new_value
-------+---------+-----------+-----------
 {a}   | replace | 1         | 2
 {b,1} | replace | 2         | 5
 {b,2} | remove  | 3         |
 {c,x} | remove  | 1         |
 {c,y} | add     |           | 1
 {d}   | add     |           | null
```

Arrays are compared by position. To check only whether two documents are equal, use `a::jsonb = b::jsonb`.

### Merge

| Function | Behavior |
|---|---|
| `merge_deep(a, b)` | Merges objects at every level; on any other conflict `b` wins (`\|\|` only merges the top level) |
| `merge_patch(target, patch)` | [JSON Merge Patch, RFC 7396](https://www.rfc-editor.org/rfc/rfc7396): same, but `null` in the patch **removes** the key |

```sql
SELECT jsonvd.merge_deep('{"db":{"host":"localhost","port":5432}}', '{"db":{"port":6543}}');
--  {"db": {"host": "localhost", "port": 6543}}
```

### Modification

| Function | Behavior |
|---|---|
| `push(doc, key, value jsonb)` | Adds or replaces a key in an object |
| `push(doc, key, value text)` | Same, inferring the type: `'1'` → `1`, `'false'` → `false`, `'hello'` → `"hello"` |
| `set_path(doc, path, value)` | Like `jsonb_set`, but **creates missing intermediate objects** |
| `delete_key_deep(doc, key)` | Removes a key at every level (e.g. `password`) |

```sql
SELECT jsonvd.set_path('{}', '{config,db,port}', '5432');
--  {"config": {"db": {"port": 5432}}}
```

### Type and schema inference

| Function | Returns |
|---|---|
| `parse_value(text)` | The JSON value a text represents (`null`, boolean, number, object, array or string) |
| `typeof_text(text)` | The JSON type of that value |
| `build_object(VARIADIC text[])` | An object from text key/value pairs, inferring types |
| `infer_schema(rows)` | Suggested PostgreSQL type per key of an array of objects (`bigint`, `numeric`, `boolean`, `date`, `timestamp`, `timestamptz`, `text`, `jsonb`) |
| `recordset_definition(rows)` | The column list ready for `jsonb_to_recordset` |

```sql
SELECT jsonvd.recordset_definition('[{"id":1,"name":"Vlade","since":"2024-01-01"}]');
--  id bigint, name text, since date

-- Build and run the typed query from psql
SELECT format('SELECT * FROM jsonb_to_recordset(%L) AS t(%s)', doc, jsonvd.recordset_definition(doc))
FROM data \gexec
```

`parse_value` follows the JSON grammar: `'007'`, `'1.'` and `'TRUE'` stay strings.

### Legacy path format

The original procedures took paths like `[{"clave": "node", "posicion": 2}, {"posicion": 1}]`
(`clave` = key, `posicion` = position).

| Function | Returns |
|---|---|
| `legacy_path(doc, steps)` | The equivalent `text[]` path, for `#>`, `#>>` and `jsonb_set` |
| `to_legacy_path(doc, path)` | The reverse conversion |

Rules (identical to the originals): at each step, if the current node is an array, `posicion` is
taken; then the path enters `clave`, **except on the last step**, where `clave` names the key to be
read or written.

```sql
SELECT doc #> jsonvd.legacy_path(doc, '[{"clave":"nodo_maluma","posicion":2},{"posicion":1}]');
```

## Migrating from the original procedures

Many of the original functions now have a native PostgreSQL equivalent:

| Original | Today |
|---|---|
| `json_pushVD`, `json_push_vd` | `doc \|\| jsonb_build_object('k', v)` or `jsonvd.push(doc, 'k', 'v')` |
| `json_deleteVD(doc, 'k')` | `doc - 'k'` |
| `json_deleteVD(arr, 'k', 1)` | `doc #- '{1,k}'` |
| `add_position_jsonVD` | `jsonvd.set_path(doc, jsonvd.legacy_path(doc, pos) \|\| 'k', v)` |
| `return_jsonVD`, `sub_return_jsonVD` | `doc #> jsonvd.legacy_path(doc, pos)` |
| `return_json_valueVD` | `doc #> jsonvd.legacy_path(doc, pos) ->> 'k'` |
| `compare_jsonVD` | `a::jsonb = b::jsonb` or `jsonvd.diff(a, b)` |
| `search_jsonVD` | `jsonvd.contains_deep(doc, target)` |
| `search_positionVD`, `extract_positionVD` | `jsonvd.find_path(doc, target)` |
| `to_json_build_vd`, `json_agg_build_vd` | `jsonvd.build_object(...)` / `jsonb_build_object(...)` |
| `convert_array_jsonVD` | `jsonb_build_array(...)` / `jsonb_agg(...)` |
| `typeof_vd` | `jsonvd.typeof_text(txt)` |
| `probando_locura` | `jsonvd.recordset_definition(doc)` + `jsonb_to_recordset` |
| `valid_json_positionVD` | Not needed: `legacy_path` treats a missing `posicion` as 0 |

### Compatibility layer

For systems that already call the old names, [`compat/jsonvd_legacy.sql`](compat/jsonvd_legacy.sql)
recreates them with the same signatures, implemented on top of `jsonvd`:

```bash
psql -d mydb -f compat/jsonvd_legacy.sql
```

Behavior changes from the originals (all of them bug fixes):

- No longer break on apostrophes, quotes, `#`, `$$`, empty arrays or arrays of scalars.
- Invalid input raises an error instead of returning `{"ERROR": ...}`.
- `json_push_vd('{"a":1}', 'Prueba', '1')` returns `{"a":1,"Prueba":1}` (it used to return `{"a":1,"prueba":true}`).
- `compare_jsonVD('[1,1]', '[2,2]')` returns `Jsons Distintos` (it used to report them as equal).
- The original Spanish result messages are kept (`No existe`, `La clave no existe`, `No se encuentra el objecto`) so existing callers keep working.

## Development

```bash
make installcheck          # with a local PostgreSQL and pg_config on PATH
scripts/test.sh            # with Docker: runs the suite on PostgreSQL 14, 15, 16, 17 and 18
scripts/test.sh 17         # a single version
```

Tests use `pg_regress`: each `test/sql/*.sql` is run and its output compared with `test/expected/*.out`.

```
jsonvd.control             extension metadata
sql/jsonvd--1.0.0.sql      every function
compat/jsonvd_legacy.sql   old names on top of the new API
test/                      regression tests
legacy/                    the original procedures (2018, Spanish), kept for reference
```

## License

[MIT](LICENSE) © Vlade Párica
