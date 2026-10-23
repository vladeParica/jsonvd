# PRD — Type and schema inference

> **AI-DLC phase:** `01-requirements`  ·  **Status:** `in review`
> **Author:** Vlade Párica  ·  **Date:** 2026-10-23

## 1. Problem
Values often arrive as text (form fields, CSV, query parameters) and must become typed JSON; arrays of
JSON objects often need to become typed rows, but `jsonb_to_recordset` needs a hand-written column list.
The legacy `typeof_vd` / `json_push_vd` misclassified values (`'1'` became `true`, `'yes'` became a
boolean and then crashed) and `probando_locura` emitted invalid types (`number`).

## 2. Users and actors
**Caller**.

## 3. Main flow (happy path)
1. **Value inference:** `parse_value('15')` → `15`; `typeof_text('15')` → `number`;
   `build_object('id','15','active','true')` → `{"id": 15, "active": true}`.
2. **Schema inference:** `infer_schema(rows)` returns `(key, pg_type)` per key of an array of objects;
   `recordset_definition(rows)` returns the column list for `jsonb_to_recordset(...) AS t(<list>)`.

## 4. Business rules
- `parse_value` follows the JSON grammar: `null`, `true`, `false`, JSON numbers, and valid
  objects/arrays/quoted strings become that JSON; everything else becomes a string. JSON is case
  sensitive (`'TRUE'` is a string); `'007'` and `'1.'` are strings; surrounding spaces are ignored for
  detection.
- `infer_schema` types per key, ignoring `null`s: all integers up to 18 digits → `bigint`; other numbers →
  `numeric`; booleans → `boolean`; ISO dates → `date`; ISO timestamps → `timestamp` or `timestamptz`
  (with offset); other strings → `text`; objects, arrays or mixed types → `jsonb`; only `null`s → `text`.
- Keys are listed by first appearance; column names are quoted when needed (`format('%I')`).

## 5. Edge, abuse and risk scenarios
| Scenario | Expected system behavior |
|---|---|
| Malformed JSON-looking text (`'{broken'`) | Returned as a string, no error |
| Numbers too large for `numeric` | Returned as a string, no error |
| Odd number of arguments to `build_object` | Error `invalid_parameter_value` |
| `NULL` key in `build_object` | Error `null_value_not_allowed` |
| `NULL` value in `build_object` | Stored as JSON `null` |
| Keys that are SQL keywords or contain spaces (`select`, `Full Name`) | Quoted in `recordset_definition` |
| Empty array or array without objects | `infer_schema` → no rows; `recordset_definition` → `NULL` |
| Integer beyond `bigint` range | Typed `numeric` |

## 6. Acceptance criteria
- [x] Each input in the documented table infers the expected value and type — `test/sql/parse.sql`.
- [x] `build_object` infers types and raises the documented errors — `test/sql/build.sql`.
- [x] `infer_schema` produces the documented types, and the generated query runs — `test/sql/schema.sql`.

## 7. Out of scope
- Locale-specific formats (e.g. `1.234,5`, `dd/mm/yyyy`).
- Creating tables or views from the inferred schema.

## 8. Open decisions (Human-in-the-Loop)
- None.
