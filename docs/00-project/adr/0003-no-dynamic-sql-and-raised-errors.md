# ADR-0003 — No dynamic SQL and raised errors

> **AI-DLC phase:** `02-design`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
The legacy functions built SQL by concatenating input values (quoted with `$$` or by replacing `"` with
`'`) and ran it with `EXECUTE`. Verified against PostgreSQL 17, this made them fail on ordinary data — an
apostrophe (`O'Brien`), a `#`, or `$$` inside a value — and made them injectable. They also caught
`WHEN others` and returned the message as data (`{"ERROR": ...}`, `'No existe'`), hiding real bugs and
forcing callers to compare strings.

## Decision
1. No library function builds SQL from values. Values are only handled as `jsonb`/`text` data. The single
   `EXECUTE` in the project (`probando_locura` in the compat layer) quotes identifiers with `format('%I')`
   and passes the data with `USING`.
2. Invalid input raises an error with `RAISE EXCEPTION ... USING ERRCODE`, using standard SQLSTATEs
   (`invalid_parameter_value`, `null_value_not_allowed`, `invalid_text_representation`).

## Alternatives considered
- **Keep dynamic SQL with better quoting (`quote_literal`)** — rejected: still slower (no plan caching) and
  easy to get wrong; the native `jsonb` functions make it unnecessary.
- **Keep returning errors as data** — rejected: callers cannot use standard error handling, and a JSON
  "error" can be mistaken for a valid document.

## Consequences
- **Positive:** no injection surface, correct behavior on any input, errors are catchable by SQLSTATE.
- **Negative / costs:** the compat layer changes behavior for callers that relied on `{"ERROR": ...}`
  results; this is documented in `docs/05-deployment/migration-from-legacy.md`.
- **Open (Human-in-the-Loop):** none.
