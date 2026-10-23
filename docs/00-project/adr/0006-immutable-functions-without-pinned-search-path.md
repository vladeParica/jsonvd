# ADR-0006 — Immutable functions without pinned search_path

> **AI-DLC phase:** `02-design`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
The legacy functions were all `VOLATILE`, which stops the planner from caching or inlining them and rules
them out of expression indexes. Every `jsonvd` function is a pure function of its arguments.
Separately, PostgreSQL's security guidance suggests pinning `search_path` (`SET search_path = ...`) on
functions so that objects created by other users cannot shadow the ones the function calls; however, a
`SET` clause prevents SQL functions from being inlined.

## Decision
1. Mark every pure function `IMMUTABLE PARALLEL SAFE`, and `STRICT` where a `NULL` input must yield `NULL`.
2. Do not pin `search_path`. Instead, every call to a `jsonvd` function inside the extension is
   schema-qualified with `@extschema@`, the functions are `SECURITY INVOKER` (the default), and none is
   `SECURITY DEFINER`.

## Alternatives considered
- **`SET search_path = pg_catalog, @extschema@` on every function** — rejected for 1.0: disables inlining
  of the SQL functions, and because the functions run with the caller's privileges, a shadowed operator
  can only affect the caller's own session.
- **`STABLE`** — rejected: the functions do not read the database or depend on settings.

## Consequences
- **Positive:** usable in expression indexes and generated columns, eligible for parallel plans, SQL
  functions can be inlined.
- **Negative / costs:** built-in operators (`||`, `->`, `=`) are resolved through the caller's
  `search_path`; a caller who puts a hostile schema before `pg_catalog` affects only their own session.
  Recorded in `docs/02-design/threat-model.md`.
- **Open (Human-in-the-Loop):** none.
