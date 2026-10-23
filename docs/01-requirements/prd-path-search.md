# PRD — Path search

> **AI-DLC phase:** `01-requirements`  ·  **Status:** `in review`
> **Author:** Vlade Párica  ·  **Date:** 2026-10-23

## 1. Problem
PostgreSQL reads a node at a known path (`#>`) but cannot answer "where is this value?". Callers need the
path to update a node with `jsonb_set`, to report where something was found, or just to know whether a
value exists anywhere in a document. The legacy `search_jsonVD` / `search_positionVD` tried this but
compared text with spaces stripped and crashed on arrays of scalars.

## 2. Users and actors
**Caller** (an application or a DBA writing SQL).

## 3. Main flow (happy path)
1. The caller passes a **document** and a **target** to `find_path`.
2. jsonvd walks every **node** in **document order** and compares it with the target by **jsonb equality**.
3. It returns the **path** of the first match; `find_paths` returns all matches; `contains_deep` returns
   whether there is any.
4. The caller uses the path directly with `#>` or `jsonb_set`.
5. `flatten` exposes the same walk as rows (`path`, `value`, `type`, `depth`) for ad-hoc analysis.

## 4. Business rules
- Matching is by jsonb equality: whitespace and key order do not matter; strings are compared exactly.
- The root node is a candidate (its path is `{}`).
- Array positions in paths are zero-based text, as the native operators expect.
- Results are in document order.

## 5. Edge, abuse and risk scenarios
| Scenario | Expected system behavior |
|---|---|
| Target not present | `find_path` → `NULL`, `find_paths` → no rows, `contains_deep` → `false` |
| Target appears several times | `find_path` returns the first in document order; `find_paths` returns all |
| Target is a partial object (`{"id":2}` vs `{"id":2,"x":1}`) | No match — equality, not containment (use `@>` for containment) |
| Strings that differ only by spaces | No match (legacy bug fixed) |
| Arrays of scalars in the document | Walked normally (legacy crash fixed) |
| `NULL` document or target | `NULL` result (functions are `STRICT`) |
| Very large or deeply nested document | Completes; memory grows with size × depth. See known gaps in `docs/04-testing/test-strategy.md` |

## 6. Acceptance criteria
- [x] The returned path, used with `#>`, yields a value equal to the target — `test/sql/paths.sql`.
- [x] Key order and whitespace in the target do not affect matching — `test/sql/paths.sql`.
- [x] `find_paths` returns every occurrence in document order — `test/sql/paths.sql`.
- [x] `contains_deep` does not confuse `"Avión Comercial"` with `"AviónComercial"` — `test/sql/paths.sql`.
- [x] `flatten` lists every node with its type and depth — `test/sql/paths.sql`.

## 7. Out of scope
- Pattern or predicate search — use jsonpath (`jsonb_path_query`).
- Containment search (`@>`) — native.

## 8. Open decisions (Human-in-the-Loop)
- None.
