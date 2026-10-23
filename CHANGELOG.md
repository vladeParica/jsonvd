# Changelog

## Unreleased

Repository and tooling only; the extension itself (`sql/`, `compat/`) is unchanged.

- PGXN distribution metadata (`META.json`) and a `Release` workflow that builds the PGXN bundle and the
  GitHub release from version tags.
- CI: `actions/checkout` v5, one run per change, Dependabot for GitHub Actions.
- Community files: code of conduct, security policy, issue forms and pull request template.
- Release archives no longer include `.github`, `.ai-dlc`, `Logo` and `legacy`.

## 1.0.0 — 2026-10-23

First release as a PostgreSQL extension (`CREATE EXTENSION jsonvd`), rewritten
from the original 2018 procedures (kept in `legacy/`). Supports PostgreSQL 14–18.

- Search: `find_path`, `find_paths`, `contains_deep`, `flatten`.
- Comparison: `diff`.
- Merge: `merge_deep`, `merge_patch` (RFC 7396).
- Modification: `push`, `set_path`, `delete_key_deep`.
- Inference: `parse_value`, `typeof_text`, `build_object`, `infer_schema`, `recordset_definition`.
- Legacy paths: `legacy_path`, `to_legacy_path`.
- `compat/jsonvd_legacy.sql`: the original names on top of the new API.
- `pg_regress` test suite and CI on PostgreSQL 14 to 18.
