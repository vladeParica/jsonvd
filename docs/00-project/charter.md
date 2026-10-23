# Project charter — jsonvd

> **AI-DLC phase:** `00-project`  ·  **Status:** `draft`
> **Owner:** Vlade Párica  ·  **Date:** 2026-10-23

## Vision
Give PostgreSQL users the JSON operations the engine does not ship with — finding where a value lives,
comparing and merging documents, and inferring types and schemas — as a small, safe, installable
extension.

## Context
In 2018 the author wrote a set of PL/pgSQL procedures (`legacy/`) to fill gaps in PostgreSQL 9.x's JSON
support. Since then PostgreSQL added most of what they did natively (`jsonb_set`, `jsonb_insert`, `#>`,
`#-`, jsonpath, subscripting). Running the originals on PostgreSQL 17 showed they are also unreliable:

- Values with an apostrophe, `#` or `$$` break them (SQL built by string concatenation).
- `json_push_vd(obj, 'Prueba', '1')` stores `{"prueba": true}`; `'false'` is stored as the string
  `"false"`; pushing into `[]` returns invalid JSON (`[,{...}]`).
- `compare_jsonVD('[1,1]', '[2,2]')` reports the documents as equal and crashes on object vs array.
- `search_positionVD` and `add_position_jsonVD` cannot run (missing functions); `search_jsonVD` crashes on
  any array of scalars.

A few ideas in them are still not covered by PostgreSQL: returning the **path** of a value, inferring a
typed record set from JSON, and the `[{"clave","posicion"}]` path format used by existing systems.

## Problem
PostgreSQL can read a value at a known path, but it cannot tell you where a value is, diff two documents,
merge them deeply, or suggest column types for a JSON array. Teams write ad-hoc, often unsafe PL/pgSQL for
this. Systems already using the original procedures are running buggy code.

## Scope
**In scope**
- Path search: `find_path`, `find_paths`, `contains_deep`, `flatten`.
- Comparison and merge: `diff`, `merge_deep`, `merge_patch` (RFC 7396).
- Modification helpers missing natively: `push` with type inference, `set_path`, `delete_key_deep`.
- Inference: `parse_value`, `typeof_text`, `build_object`, `infer_schema`, `recordset_definition`.
- Legacy support: `legacy_path`, `to_legacy_path` and the `compat/jsonvd_legacy.sql` layer.

**Out of scope (explicit, not omissions)**
- Re-implementing what PostgreSQL already provides (`jsonb_set`, `-`, `#-`, `#>`, jsonpath) — the docs map
  the old functions to the native ones instead ([ADR-0002](adr/0002-pure-sql-and-pl-pgsql-on-jsonb.md)).
- The `json` type as a first-class input — use `jsonb`.
- C code or other procedural languages ([ADR-0002](adr/0002-pure-sql-and-pl-pgsql-on-jsonb.md)).
- PostgreSQL versions without upstream support ([ADR-0004](adr/0004-support-postgresql-14-and-later.md)).

## Success metrics
- The test suite passes on every upstream-supported PostgreSQL major version.
- Every behavior change from the legacy procedures is documented and covered by a test.
- Systems using the old names migrate by running a single script, with no code changes.
- `<TODO — Human-in-the-Loop: adoption target, e.g. PGXN publication, GitHub stars or known users>`

## Principles / non-negotiables
- No SQL built from values ([ADR-0003](adr/0003-no-dynamic-sql-and-raised-errors.md)).
- Errors are raised, never returned as data ([ADR-0003](adr/0003-no-dynamic-sql-and-raised-errors.md)).
- Pure functions are `IMMUTABLE PARALLEL SAFE` ([ADR-0006](adr/0006-immutable-functions-without-pinned-search-path.md)).
- No feature that duplicates a native PostgreSQL function.
- Every change ships with a regression test ([ADR-0007](adr/0007-regression-tests-with-pg-regress-and-docker.md)).

## Key risks
| Risk | Impact | Mitigation / owner |
|---|---|---|
| Recursive functions on very large or deep documents use a lot of memory | Slow queries, memory pressure | Documented limits; benchmark in `docs/04-testing/test-strategy.md` — owner: maintainer |
| Compat layer behavior changes surprise existing callers | Broken integrations during migration | Migration guide lists every change — owner: maintainer |
| Native PostgreSQL adds equivalents in future versions | Parts of the API become redundant | Deprecate in favor of native functions via ADR — owner: maintainer |
| Managed databases cannot install custom extensions | Limited reach | Script-based install fallback in the deploy guide — owner: maintainer |

## Open decisions (Human-in-the-Loop)
- `<TODO — Human-in-the-Loop: publish to PGXN, and when>`
- `<TODO — Human-in-the-Loop: release cadence and versioning policy (e.g. SemVer for function signatures)>`
