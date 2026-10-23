# PRD — Compare and transform documents

> **AI-DLC phase:** `01-requirements`  ·  **Status:** `in review`
> **Author:** Vlade Párica  ·  **Date:** 2026-10-23

## 1. Problem
Callers need to know what changed between two versions of a document (auditing, sync, change review), to
apply a partial update to a nested document, and to make small edits that the native functions make
awkward. PostgreSQL's `||` only merges the top level, `jsonb_set` does not create missing parents, and
there is no diff. The legacy `compare_jsonVD` gave wrong answers and `json_pushVD` corrupted values.

## 2. Users and actors
**Caller**.

## 3. Main flow (happy path)
1. **Diff:** the caller passes two documents to `diff` and gets one row per change: path, operation
   (`add` / `remove` / `replace`), old value, new value.
2. **Merge:** the caller combines a base document with a partial one using `merge_deep`, or applies an
   RFC 7396 patch with `merge_patch` (where `null` removes a key).
3. **Edit:** the caller adds a key with `push`, writes at a path that may not exist yet with `set_path`,
   or strips a key at every level with `delete_key_deep`.

## 4. Business rules
- `diff` recurses only when both sides are objects or both are arrays; arrays are compared by position;
  equal sub-documents produce no rows.
- `merge_deep`: object/object merges key by key; any other conflict is won by the second argument; SQL
  `NULL` on either side returns the other side.
- `merge_patch` follows RFC 7396 exactly.
- `push(doc, key, text)` infers the type of the value (see the inference PRD); `push` only accepts objects.
- `set_path` creates missing intermediate objects, replaces JSON `null` parents, and refuses to descend
  into a scalar.

## 5. Edge, abuse and risk scenarios
| Scenario | Expected system behavior |
|---|---|
| Equal documents with different whitespace or key order | `diff` returns no rows |
| `[1,1]` vs `[2,2]` | Two `replace` rows (legacy reported "equal") |
| Object vs array at the same path | One `replace` row |
| One side SQL `NULL` | `diff` reports the root as `add` or `remove` |
| An element inserted at the start of an array | Reported as replaces plus an `add` at the end (positional comparison, documented) |
| `push` on an array or scalar | Error `invalid_parameter_value` |
| `set_path` through a number or string | Error `invalid_parameter_value`, naming the path and type |
| `set_path` with an empty path | Returns the new value (replaces the whole document) |
| Values with quotes, apostrophes, `#`, `$$` | Handled as data, never break the function |
| `delete_key_deep` on a scalar or empty array | Returned unchanged |

## 6. Acceptance criteria
- [x] `diff` output matches the documented example and is empty for equal documents — `test/sql/diff.sql`.
- [x] Array indexes in `diff` are ordered numerically (`{2}` before `{11}`) — `test/sql/diff.sql`.
- [x] `merge_patch` passes all RFC 7396 appendix A cases — `test/sql/merge.sql`.
- [x] `merge_deep` keeps sibling keys that `||` would drop — `test/sql/merge.sql`.
- [x] `push`, `set_path` and `delete_key_deep` behave as in the rules above, including errors — `test/sql/mutate.sql`.

## 7. Out of scope
- Generating or applying RFC 6902 JSON Patch documents.
- Array diff by content (LCS / move detection).

## 8. Open decisions (Human-in-the-Loop)
- `<TODO — Human-in-the-Loop: whether to add RFC 6902 JSON Patch output (diff_patch / apply_patch) in a future version>`
