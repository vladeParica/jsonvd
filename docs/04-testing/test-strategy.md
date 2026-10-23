# Test strategy — jsonvd

> **AI-DLC phase:** `04-testing`
> How the library is verified — including the edge and abuse scenarios from the PRDs, not just the happy
> path ([ADR-0007](../00-project/adr/0007-regression-tests-with-pg-regress-and-docker.md)).

## Levels
| Level | Scope | Tooling | What it covers |
|---|---|---|---|
| Regression (unit) | Each public function | `pg_regress` (`make installcheck`) | Outputs compared byte for byte with `test/expected/*.out` |
| Compatibility | Compat layer vs legacy behavior | `pg_regress` (`test/sql/compat.sql`) | Old names, signatures, messages and the fixed bugs |
| Equivalence | `legacy_path` vs the original procedures | Manual run against the legacy functions (PostgreSQL 17) | Same results on the examples from the originals' source; encoded in `test/sql/legacy.sql` |
| Cross-version | Whole suite | Docker (`scripts/test.sh`), GitHub Actions matrix | PostgreSQL 14, 15, 16, 17, 18 |
| Performance (benchmark) | Traversal | Manual `\timing` run | 2,000-object document: `contains_deep` ~48 ms vs ~64 ms legacy `search_jsonVD` |

## Test files
| File | Covers | PRD |
|---|---|---|
| `test/sql/parse.sql` | `parse_value`, `typeof_text` | [Inference](../01-requirements/prd-type-and-schema-inference.md) |
| `test/sql/build.sql` | `build_object`, errors | [Inference](../01-requirements/prd-type-and-schema-inference.md) |
| `test/sql/mutate.sql` | `push`, `set_path`, `delete_key_deep`, errors | [Compare and transform](../01-requirements/prd-compare-and-transform.md) |
| `test/sql/merge.sql` | `merge_deep`, `merge_patch` (RFC 7396 appendix A) | [Compare and transform](../01-requirements/prd-compare-and-transform.md) |
| `test/sql/diff.sql` | `diff` | [Compare and transform](../01-requirements/prd-compare-and-transform.md) |
| `test/sql/paths.sql` | `flatten`, `find_path(s)`, `contains_deep` | [Path search](../01-requirements/prd-path-search.md) |
| `test/sql/schema.sql` | `infer_schema`, `recordset_definition`, generated query | [Inference](../01-requirements/prd-type-and-schema-inference.md) |
| `test/sql/legacy.sql` | `legacy_path`, `to_legacy_path`, round trip | [Legacy migration](../01-requirements/prd-legacy-migration.md) |
| `test/sql/compat.sql` | Every compat function | [Legacy migration](../01-requirements/prd-legacy-migration.md) |

## Critical / safety paths (must be covered)
- Values with apostrophes, quotes, `#` and `$$` never break a function (`mutate`, `build`, `compat`).
- Errors are raised with the documented messages, never returned as data (`build`, `mutate`, `legacy`, `compat`).
- Equality ignores whitespace and key order but not spaces inside strings (`paths`, `diff`, `compat`).
- Every legacy bug listed in the [charter](../00-project/charter.md) has a test showing the fixed behavior (`compat`).

## Fixtures / seed data
- Each test builds its own data inline or in `TEMP` tables; nothing persists between runs.
- Fixtures are synthetic (aviation license catalog, song lists) and contain no real personal data.
- Tests start with `\set VERBOSITY terse` to keep outputs identical across PostgreSQL versions.

## Updating expected outputs
1. Run the suite; it fails on the changed test.
2. Inspect `results/<test>.out` and confirm every difference is intended.
3. Copy it to `test/expected/<test>.out` and commit it with the change.

## Known gaps
| Gap | Risk | Decision (fix now / accept) |
|---|---|---|
| No automated performance or memory test for large/deep documents | Regressions in traversal cost go unnoticed | Accept for 1.0; manual benchmark documented above |
| The legacy-equivalence check was run manually, not in CI | Drift if `legacy_path` changes | Accept: results are encoded as expected outputs in `test/sql/legacy.sql` |
