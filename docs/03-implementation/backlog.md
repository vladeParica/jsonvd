# Backlog & implementation notes — jsonvd

> **AI-DLC phase:** `03-implementation`
> What's built, what's left, and the non-obvious decisions a maintainer needs.

## Status
Version 1.0.0 is implemented and passes the regression suite on PostgreSQL 14–18.

## Done
- [x] Extension packaging: `jsonvd.control`, `sql/jsonvd--1.0.0.sql`, PGXS `Makefile` — [ADR-0001](../00-project/adr/0001-package-as-a-postgresql-extension.md)
- [x] Path search: `flatten`, `find_path`, `find_paths`, `contains_deep`
- [x] Diff and merge: `diff`, `merge_deep`, `merge_patch`
- [x] Building and modification: `build_object`, `push`, `set_path`, `delete_key_deep`
- [x] Inference: `parse_value`, `typeof_text`, `infer_schema`, `recordset_definition`
- [x] Legacy paths: `legacy_path`, `to_legacy_path` — [ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)
- [x] Compat layer: `compat/jsonvd_legacy.sql`
- [x] Compat errors no longer echo input values (`convert_array_jsonVD`) — #2
- [x] Regression suite, Docker test script, CI on PostgreSQL 14–18 — [ADR-0007](../00-project/adr/0007-regression-tests-with-pg-regress-and-docker.md)
- [x] Repository governance: MIT license, rulesets, CODEOWNERS — [ADR-0008](../00-project/adr/0008-repository-governance-and-licensing.md)

## In progress / remaining
- [ ] Publish to PGXN (#8): `META.json` and the release workflow are ready; needs the maintainer's PGXN
      account and the `PGXN_USERNAME` / `PGXN_PASSWORD` secrets.
- [ ] Define the upgrade-script process for 1.1.0 (`sql/jsonvd--1.0.0--1.1.0.sql`) — see the deploy guide.
- [ ] Drop PostgreSQL 14 in 1.1.0 (#20) — [ADR-0010](../00-project/adr/0010-track-upstream-supported-postgresql-versions.md).

## Implementation notes
- **Last-step rule of legacy paths.** Found by running the originals: the `clave` of the last step is not
  entered. `to_legacy_path` closes paths that end inside a key with an empty step `{}` so the round trip
  holds.
- **Recursive functions are PL/pgSQL.** A SQL-language function cannot call itself: its body is validated
  at `CREATE` time, before the function exists. `merge_deep`, `merge_patch` and `delete_key_deep` are
  therefore PL/pgSQL.
- **Type guards inside `LATERAL`.** `_nodes` and `diff` pass `CASE WHEN jsonb_typeof(x) = 'object' THEN x
  ELSE '{}' END` to `jsonb_each` / `jsonb_array_elements` instead of filtering with `WHERE`, because the
  planner does not guarantee the filter runs before the function, and those functions raise on the wrong
  type.
- **Document order.** `_nodes` carries a `bigint[]` of ordinals per level; ordering by it gives pre-order
  with numeric array indexes (`{2}` before `{11}`), which ordering by the `text[]` path would not.
- **jsonb key order.** `jsonb` stores keys shortest-first, so outputs (and `infer_schema` column order)
  follow that order, not the original text.
- **Exception block in `parse_value`.** Only entered for JSON-looking input; catches `data_exception`
  (class 22) so malformed JSON and numeric overflow both fall back to a string.
- **Tests and `\i`.** `pg_regress` feeds each file through stdin, so `\ir` does not resolve relative to the
  test file; `test/sql/compat.sql` uses `\i compat/jsonvd_legacy.sql`, relative to the repository root.

## Deviations from design
| Design said | We did | Why | ADR |
|---|---|---|---|
| — | — | No deviations: this design was written after the 1.0.0 implementation and describes it as built | — |
