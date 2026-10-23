# Monitoring & observability — jsonvd

> **AI-DLC phase:** `06-monitoring`
> jsonvd runs inside the caller's database and has no process of its own. "Health" means two things:
> the project is releasable (CI), and the functions behave well in the databases that use them.

## Health
- **Project:** the CI badge on the README — green means the suite passes on every supported PostgreSQL
  version for the latest commit on `main`.
- **Installation:** `SELECT jsonvd.version();` returns the installed version;
  `SELECT extversion FROM pg_extension WHERE extname = 'jsonvd';` shows what the catalog has.

## Key metrics
| Metric | Why it matters | Source |
|---|---|---|
| Calls and total/self time per function | Spot heavy callers (e.g. traversal on huge documents) | `pg_stat_user_functions` (needs `track_functions = 'pl'`; SQL functions that get inlined are not counted) |
| Slow statements that call `jsonvd.*` | Find documents too large for recursive traversal | `pg_stat_statements`, `log_min_duration_statement` |
| CI pass rate on `main` / `develop` | Release readiness | GitHub Actions |
| Open issues labeled `bug` | Library quality | GitHub Issues |

```sql
SELECT funcname, calls, round(total_time) AS total_ms, round(self_time) AS self_ms
FROM   pg_stat_user_functions
WHERE  schemaname = 'jsonvd'
ORDER  BY total_time DESC;
```

## Alerts
| Condition | Severity | Who / action |
|---|---|---|
| CI fails on `main` | High | Maintainer: fix or revert before the next release |
| CI fails on a new PostgreSQL major version | Medium | Maintainer: open an issue, add it to the matrix per [ADR-0010](../00-project/adr/0010-track-upstream-supported-postgresql-versions.md) |
| A `jsonvd` call hits `statement_timeout` in a user's database | User-defined | The user's DBA: reduce document size or raise the limit |

## SLOs
- `<TODO — Human-in-the-Loop: response targets for issues and security reports, if any>`
- Supported versions: every upstream-supported PostgreSQL major version is tested in CI.

## Dashboards / logs
- GitHub Actions: `https://github.com/vladeParica/jsonvd/actions`
- Server logs of the host database for errors raised by `jsonvd` functions (messages are prefixed with the
  function name, e.g. `jsonvd.set_path:`).
