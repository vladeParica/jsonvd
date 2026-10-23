# API contracts — jsonvd

> **AI-DLC phase:** `02-design`
> jsonvd's API is a set of SQL functions, not HTTP endpoints. The source of truth is
> `sql/jsonvd--1.0.0.sql` (each function also has a `COMMENT ON FUNCTION`, visible with `\df+ jsonvd.*`);
> the expected outputs in `test/expected/` show the exact behavior.

## Conventions
- Schema: `jsonvd`. Call functions schema-qualified (`jsonvd.find_path(...)`).
- Types: documents are `jsonb`; paths are `text[]`, compatible with `#>`, `#>>`, `#-` and `jsonb_set`.
- `NULL`: functions marked **strict** return `NULL` if any argument is `NULL`.
- Errors: raised with a SQLSTATE (see the last column); never returned as data
  ([ADR-0003](../00-project/adr/0003-no-dynamic-sql-and-raised-errors.md)).
- Volatility: every function is `IMMUTABLE PARALLEL SAFE`
  ([ADR-0006](../00-project/adr/0006-immutable-functions-without-pinned-search-path.md)).

## Path search
| Function | Strict | Returns | Errors |
|---|---|---|---|
| `find_path(doc jsonb, target jsonb)` | yes | `text[]` — first path where `target` appears (document order), or `NULL` | — |
| `find_paths(doc jsonb, target jsonb)` | yes | `SETOF text[]` — every path, in document order | — |
| `contains_deep(doc jsonb, target jsonb)` | yes | `boolean` — `target` appears at any level (root included) | — |
| `flatten(doc jsonb)` | yes | `TABLE(path text[], value jsonb, type text, depth integer)` — one row per node | — |

```sql
SELECT jsonvd.find_path(doc, '{"idCategoria": 7, "categoria": "Planeador"}');
--  {tramites,1,tipos,1,categorias,0}

UPDATE tramites
SET    doc = jsonb_set(doc, jsonvd.find_path(doc, '"Piloto Privado - Avión"'), '"Piloto Privado"')
WHERE  jsonvd.contains_deep(doc, '"Piloto Privado - Avión"');
```

## Diff and merge
| Function | Strict | Returns | Errors |
|---|---|---|---|
| `diff(a jsonb, b jsonb)` | no | `TABLE(path text[], op text, old_value jsonb, new_value jsonb)` — `op` is `add`, `remove` or `replace`; arrays compared by position | — |
| `merge_deep(a jsonb, b jsonb)` | no | `jsonb` — objects merged at every level; other conflicts won by `b`; `NULL` side ignored | — |
| `merge_patch(target jsonb, patch jsonb)` | no | `jsonb` — RFC 7396 JSON Merge Patch (`null` removes the key) | — |

```sql
SELECT * FROM jsonvd.diff('{"a":1,"b":[1,2,3],"c":{"x":1}}',
                          '{"a":2,"b":[1,5],"c":{"y":1},"d":null}');
--  {a}   | replace | 1 | 2
--  {b,1} | replace | 2 | 5
--  {b,2} | remove  | 3 |
--  {c,x} | remove  | 1 |
--  {c,y} | add     |   | 1
--  {d}   | add     |   | null

SELECT jsonvd.merge_deep('{"db":{"host":"localhost","port":5432}}', '{"db":{"port":6543}}');
--  {"db": {"host": "localhost", "port": 6543}}
```

## Building and modification
| Function | Strict | Returns | Errors |
|---|---|---|---|
| `push(doc jsonb, key text, value jsonb)` | yes | `jsonb` — `doc` with `key` added or replaced | `22023` if `doc` is not an object |
| `push(doc jsonb, key text, value text)` | yes | Same, with `value` inferred by `parse_value` | `22023` if `doc` is not an object |
| `set_path(doc jsonb, path text[], value jsonb)` | yes | `jsonb` — like `jsonb_set`, creating missing intermediate objects; empty path returns `value` | `22023` if the path crosses a scalar |
| `delete_key_deep(doc jsonb, key text)` | yes | `jsonb` — `key` removed at every level | — |
| `build_object(VARIADIC pairs text[])` | yes | `jsonb` — object from key/value pairs, values inferred; SQL `NULL` value → JSON `null` | `22023` odd argument count; `22004` `NULL` key |

```sql
SELECT jsonvd.push('{"a":1}', 'Prueba', '1');            --  {"a": 1, "Prueba": 1}
SELECT jsonvd.set_path('{}', '{config,db,port}', '5432'); --  {"config": {"db": {"port": 5432}}}
```

## Inference
| Function | Strict | Returns | Errors |
|---|---|---|---|
| `parse_value(txt text)` | yes | `jsonb` — the JSON value the text represents; anything that is not valid JSON becomes a string | — |
| `typeof_text(txt text)` | yes | `text` — `null`, `boolean`, `number`, `string`, `object` or `array` | — |
| `infer_schema(rows jsonb)` | yes | `TABLE(key text, pg_type text)` — `bigint`, `numeric`, `boolean`, `date`, `timestamp`, `timestamptz`, `text` or `jsonb`, by first appearance | — |
| `recordset_definition(rows jsonb)` | yes | `text` — column list for `jsonb_to_recordset(...) AS t(<list>)`, identifiers quoted; `NULL` if there are no keys | — |

```sql
SELECT jsonvd.recordset_definition('[{"id":1,"name":"Vlade","since":"2024-01-01"}]');
--  id bigint, name text, since date

-- From psql: build and run the typed query
SELECT format('SELECT * FROM jsonb_to_recordset(%L) AS t(%s)', doc, jsonvd.recordset_definition(doc))
FROM data \gexec
```

## Legacy paths
| Function | Strict | Returns | Errors |
|---|---|---|---|
| `legacy_path(doc jsonb, steps jsonb)` | yes | `text[]` — the path a legacy `[{"clave","posicion"}]` path denotes in `doc` | `22023` if `steps` is not an array |
| `to_legacy_path(doc jsonb, path text[])` | yes | `jsonb` — the legacy steps for `path`; round-trips with `legacy_path` | `22023` if the path does not exist |

Rules: at each step, if the current node is an array, `posicion` is taken; then the path enters `clave`,
**except on the last step**, where `clave` names the key to read or write
([ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)).

```sql
SELECT doc #> jsonvd.legacy_path(doc, '[{"clave":"nodo_maluma","posicion":2},{"posicion":1}]');
```

## Other
| Function | Returns |
|---|---|
| `version()` | `text` — the library version (`1.0.0`) |
| `_nodes(doc jsonb)` | Internal; not part of the public API and may change without notice |

## Business rules reflected in the API
- Matching and equality always use `jsonb` equality — see [PRD: path search](../01-requirements/prd-path-search.md).
- `diff` operation names follow JSON Patch — see [PRD: compare and transform](../01-requirements/prd-compare-and-transform.md).
- Value inference follows the JSON grammar — see [PRD: type and schema inference](../01-requirements/prd-type-and-schema-inference.md).
- The legacy function signatures are documented in the [migration guide](../05-deployment/migration-from-legacy.md).
