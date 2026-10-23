# ADR-0004 — Support PostgreSQL 14 and later

> **AI-DLC phase:** `00-project`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
PostgreSQL supports each major version for five years. As of 2026-10, versions 14 to 18 are supported
upstream (14 reaches end of life in November 2026). Version 14 added `jsonb` subscripting and has mature
jsonpath; version 16 added `pg_input_is_valid`, which would avoid exception blocks in `parse_value`.

## Decision
Support PostgreSQL 14 and later. CI tests every supported major version (currently 14–18). Features that
need a newer version are not used unless the minimum is raised by a new ADR.

## Alternatives considered
- **13 or earlier** — rejected: already out of upstream support.
- **16 as minimum** (to use `pg_input_is_valid`) — rejected for 1.0: excludes many production servers for a
  minor gain; `parse_value` uses a narrow exception block instead.

## Consequences
- **Positive:** covers every upstream-supported version, so most production servers can install it.
- **Negative / costs:** cannot use newer syntax (e.g. `JSON_TABLE`, SQL/JSON query functions from 17);
  `parse_value` pays for an exception block on JSON-looking input.
- **Open (Human-in-the-Loop):** `<TODO — Human-in-the-Loop: decide whether to drop PostgreSQL 14 from CI
  and the docs after its end of life in November 2026>`
