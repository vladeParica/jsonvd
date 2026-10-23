# ADR-0001 — Package as a PostgreSQL extension

> **AI-DLC phase:** `00-project`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
The original work (2018, kept in `legacy/`) was 21 loose `.sql` files, each a `CREATE OR REPLACE
FUNCTION` in `public`, with hard-coded `OWNER TO postgres`, mixed naming (`json_pushVD` vs `json_push_vd`)
and an undeclared dependency (`query_convert_array_jsonVD`) that did not exist in the repository. There was
no install order, no versioning and no way to uninstall cleanly.

## Decision
Ship the library as a versioned PostgreSQL extension, `jsonvd`, installed with `CREATE EXTENSION jsonvd`
into its own `jsonvd` schema, built and installed with PGXS (`make install`).

## Alternatives considered
- **Keep loose scripts** — rejected: no versioning, no clean uninstall, objects mix with user objects in
  `public`, dependencies are implicit.
- **A schema-only SQL file without extension packaging** — kept only as a documented fallback for managed
  databases where custom extensions cannot be installed (see `docs/05-deployment/deploy-guide.md`).
- **C extension** — rejected, see [ADR-0002](0002-pure-sql-and-pl-pgsql-on-jsonb.md).

## Consequences
- **Positive:** atomic install/uninstall (`DROP EXTENSION`), upgrade path via `ALTER EXTENSION ... UPDATE`
  and versioned scripts, objects isolated in a dedicated schema, `pg_dump` records the extension instead
  of each function.
- **Negative / costs:** installing on a server requires file-system access (`make install`); managed
  services (RDS, Cloud SQL) only allow allow-listed extensions, so users there must use the script fallback.
- **Open (Human-in-the-Loop):** none.
