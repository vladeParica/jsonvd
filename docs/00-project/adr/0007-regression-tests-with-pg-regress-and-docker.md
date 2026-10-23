# ADR-0007 — Regression tests with pg_regress and Docker

> **AI-DLC phase:** `04-testing`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
The legacy code had no tests; its only "tests" were example queries in comments, some of which fail when
run. The library must behave the same on every supported PostgreSQL version
([ADR-0004](0004-support-postgresql-14-and-later.md)), and contributors should not need a local
PostgreSQL installation.

## Decision
- Use `pg_regress` through PGXS (`make installcheck`): `test/sql/*.sql` is executed and compared byte for
  byte with `test/expected/*.out`.
- `scripts/test.sh` runs the suite in the official `postgres:<version>` Docker images.
- GitHub Actions runs the suite on every supported version with the `pgxn/pgxn-tools` image.

## Alternatives considered
- **pgTAP** — rejected for now: an extra extension to install; `pg_regress` ships with PostgreSQL and is
  the standard for extensions.
- **Tests in an application language** (Python, Node) — rejected: adds a toolchain unrelated to the
  product.

## Consequences
- **Positive:** zero extra dependencies, the expected outputs double as executable documentation, the same
  suite runs locally and in CI.
- **Negative / costs:** expected files must be regenerated and reviewed when outputs change; any
  version-specific output (e.g. error `CONTEXT` lines) must be suppressed, so tests run with
  `\set VERBOSITY terse`; files must use LF line endings (enforced in `.gitattributes`).
- **Open (Human-in-the-Loop):** none.
