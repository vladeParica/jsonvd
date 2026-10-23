# PRD — Migration from the legacy procedures

> **AI-DLC phase:** `01-requirements`  ·  **Status:** `in review`
> **Author:** Vlade Párica  ·  **Date:** 2026-10-23

## 1. Problem
Existing systems call the legacy procedures by name and store or build **legacy paths**
(`[{"clave","posicion"}]`). They need to stop running buggy code without rewriting their callers, and new
code needs a way to use legacy paths with native operators.

## 2. Users and actors
**Caller** of the legacy procedures; the DBA who runs the migration.

## 3. Main flow (happy path)
1. The DBA installs the extension (`CREATE EXTENSION jsonvd`).
2. The DBA runs `compat/jsonvd_legacy.sql` in the schema where the old functions live; it replaces them
   with implementations on top of `jsonvd`, keeping names and signatures.
3. Callers keep working, now with correct results.
4. Over time, callers move to the native or `jsonvd` equivalents listed in
   `docs/05-deployment/migration-from-legacy.md`; `legacy_path` converts stored legacy paths to `text[]`.

## 4. Business rules
- Legacy path rule: at each step, if the current node is an array, take `posicion` (0 if missing and the
  step has `clave`); then enter `clave` — except on the last step, where `clave` names the key to read or
  write. An empty step `{}` does nothing ([ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)).
- `to_legacy_path` produces steps that `legacy_path` maps back to the same path.
- Compat functions keep the original signatures and result messages (`No existe`, `La clave no existe`,
  `No se encuentra el objecto`, `Jsons iguales`, `Jsons Distintos`).
- Compat functions fix the legacy bugs; invalid input raises an error instead of returning `{"ERROR": ...}`.

## 5. Edge, abuse and risk scenarios
| Scenario | Expected system behavior |
|---|---|
| Caller relies on `{"ERROR": ...}` results | Now receives a SQL error — listed as a breaking change in the migration guide |
| Caller relied on a legacy bug (e.g. `'1'` stored as `true`) | Now gets the correct value — listed in the migration guide |
| Legacy path points to a missing node | `return_jsonVD` → `No existe`; `return_json_valueVD` → `La clave no existe` |
| Legacy path ends on an array and a key is requested | `El Json final es un array, no consta de claves` |
| `steps` is not an array | Error `invalid_parameter_value` |
| `to_legacy_path` with a path that does not exist | Error `invalid_parameter_value` |
| Compat script run twice | Idempotent (`CREATE OR REPLACE`, `CREATE EXTENSION IF NOT EXISTS`) |

## 6. Acceptance criteria
- [x] `legacy_path` reproduces the originals' results on the examples from their own source — verified
      against the legacy functions on PostgreSQL 17; encoded in `test/sql/legacy.sql`.
- [x] `to_legacy_path` → `legacy_path` round-trips every node of a document — `test/sql/legacy.sql`.
- [x] Each compat function returns correct results for the inputs that broke the originals — `test/sql/compat.sql`.
- [x] `return_jsonVD(doc, search_positionVD(doc, x))` returns `x` — `test/sql/compat.sql`.

## 7. Out of scope
- Reproducing legacy bugs.
- `extract_positionVD` (an internal helper of `search_positionVD`) and `sub_return_*` beyond aliasing.

## 8. Open decisions (Human-in-the-Loop)
- `<TODO — Human-in-the-Loop: target date to deprecate and later remove the compat layer>`
