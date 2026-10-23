# Migrating from the legacy procedures

> **AI-DLC phase:** `05-deployment`
> For systems that use the original 2018 procedures (`legacy/`). Requirements:
> [PRD: legacy migration](../01-requirements/prd-legacy-migration.md). Decision:
> [ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md).

## Option A — keep the old names (no code changes)
```sql
CREATE EXTENSION jsonvd;
```
```bash
psql -d mydb -f compat/jsonvd_legacy.sql   # replaces the old functions in the current schema
```
The script is idempotent. It keeps the names, signatures and result messages, and fixes the bugs.

### Behavior changes (all of them bug fixes)
| Function | Before | After |
|---|---|---|
| All | Broke on apostrophes, quotes, `#`, `$$`, empty arrays, arrays of scalars | Handle any input |
| All | Returned `{"ERROR": ...}` on invalid input | Raise a SQL error |
| `json_push_vd(obj, 'Prueba', '1')` | `{"a":1,"prueba":true}` | `{"a":1,"Prueba":1}` |
| `json_push_vd(obj, 'k', 'false')` | `"k": "false"` (string) | `"k": false` |
| `json_push_vd('[]', 'k', '5')` | `[,{"k":5}]` (invalid JSON) | `[{"k": 5}]` |
| `compare_jsonVD('[1,1]', '[2,2]')` | `Jsons iguales` | `Jsons Distintos` |
| `compare_jsonVD('{"a":1}', '[1]')` | Crashed | `Jsons Distintos` |
| `typeof_vd('yes')` | `boolean` (then broke callers) | `text` |
| `typeof_vd('1.5')` | `text` | `numeric` |
| `search_positionVD`, `add_position_jsonVD` | Could not run (missing functions) | Work |
| `valid_json_positionVD` | Replaced `null` everywhere in the text (`"nullable"` → `"0able"`) | Only fills missing positions |

Result messages kept: `No existe`, `La clave no existe`, `El Json final es un array, no consta de claves`,
`No se encuentra el objecto`, `Jsons iguales`, `Jsons Distintos`.

## Option B — move to the new API
| Legacy | Replacement |
|---|---|
| `json_pushVD`, `json_push_vd` | `doc \|\| jsonb_build_object('k', v)` or `jsonvd.push(doc, 'k', 'v')` |
| `json_deleteVD(doc, 'k')` | `doc - 'k'` |
| `json_deleteVD(arr, 'k', 1)` | `doc #- '{1,k}'` |
| `add_position_jsonVD(doc, pos, 'k', v)` | `jsonvd.set_path(doc, jsonvd.legacy_path(doc, pos) \|\| 'k', jsonvd.parse_value(v))` |
| `return_jsonVD`, `sub_return_jsonVD` | `doc #> jsonvd.legacy_path(doc, pos)` |
| `return_json_valueVD`, `sub_return_json_valueVD` | `doc #> jsonvd.legacy_path(doc, pos) ->> 'k'` |
| `compare_jsonVD` | `a::jsonb = b::jsonb`, or `jsonvd.diff(a, b)` to see what changed |
| `search_jsonVD` | `jsonvd.contains_deep(doc, target)` |
| `search_positionVD`, `extract_positionVD` | `jsonvd.find_path(doc, target)` (`text[]`); `jsonvd.to_legacy_path` for the old format |
| `to_json_build_vd` | `jsonvd.build_object(...)` |
| `json_agg_build_vd` | `jsonb_build_array(jsonvd.build_object(...))` |
| `convert_array_jsonVD` | `jsonb_build_array(...)` / `jsonb_agg(...)` |
| `typeof_vd` | `jsonvd.typeof_text(txt)` |
| `probando_locura` | `jsonvd.recordset_definition(doc)` + `jsonb_to_recordset` |
| `valid_json_positionVD` | Not needed: `legacy_path` treats a missing `posicion` as 0 |

Stored legacy paths can be converted once with `jsonvd.legacy_path(doc, steps)`.
