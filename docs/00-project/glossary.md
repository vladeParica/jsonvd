# Glossary — jsonvd

> **AI-DLC phase:** `00-project`
> The ubiquitous language of the project. Every other document must use these terms consistently.

| Term | Definition |
|---|---|
| **Document** | A `jsonb` value passed to a function (`doc`). Can be an object, array or scalar. |
| **Node** | Any value inside a document, including the root. `flatten` returns one row per node. |
| **Path** | A `text[]` that locates a node, as used by the native `#>`, `#>>` and `jsonb_set`, e.g. `{tramites,1,tipos}`. Array positions are zero-based. The root's path is `{}`. |
| **Target** | The value a search looks for (`find_path`, `contains_deep`). Matched by `jsonb` equality. |
| **Document order** | Pre-order traversal: a node before its children, children in `jsonb` order. Object keys are in `jsonb` order (shorter keys first), not the original text order. |
| **jsonb equality** | PostgreSQL's `=` on `jsonb`: ignores whitespace and key order; `1` equals `1.0`. |
| **Diff** | The list of changes between two documents, using JSON Patch operation names: `add`, `remove`, `replace`. |
| **Deep merge** | `merge_deep`: objects are merged key by key at every level; any other conflict is won by the second argument. |
| **Merge patch** | `merge_patch`: RFC 7396 JSON Merge Patch — like a deep merge, but `null` removes the key. |
| **Value inference** | `parse_value`: turning a `text` into the JSON value it represents, following the JSON grammar (`'1'` → `1`, `'007'` → `"007"`). |
| **Schema inference** | `infer_schema`: suggesting a PostgreSQL type per key of an array of objects. |
| **Legacy path** | The path format of the original procedures: an array of **steps** `[{"clave": key, "posicion": n}, ...]`. `clave` is Spanish for key, `posicion` for position. Avoid calling it "old path" or "position array". |
| **Step** | One element of a legacy path. See `legacy_path` for the rules (the last step's `clave` is not entered). |
| **Legacy procedures** | The original 2018 functions in `legacy/` (`json_pushVD`, `return_jsonVD`, ...). Not installed by the extension. |
| **Compat layer** | `compat/jsonvd_legacy.sql`: the legacy procedure names reimplemented on top of `jsonvd`, installed on demand. |
| **Maintainer** | The repository owner, the only person who can approve and merge pull requests. |
| **Contributor** | Anyone who proposes a change through a pull request from a fork. |
| **Caller** | The database user or application that invokes `jsonvd` functions. Functions run with the caller's privileges. |
