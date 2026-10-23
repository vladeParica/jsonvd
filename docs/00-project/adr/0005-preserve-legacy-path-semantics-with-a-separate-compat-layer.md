# ADR-0005 — Preserve legacy path semantics with a separate compat layer

> **AI-DLC phase:** `02-design`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
Systems built on the original procedures call them by name and pass paths in the format
`[{"clave": "...", "posicion": n}, ...]`. Running the originals showed a non-obvious rule: on the **last**
step, `clave` is not entered — it names the key that will be read or written (this is how
`return_json_valueVD` and `add_position_jsonVD` use it). Several originals were also broken or buggy
(see `docs/00-project/charter.md`, Context).

## Decision
1. The core API uses native `text[]` paths. Two functions, `legacy_path` and `to_legacy_path`, convert
   between the legacy format and `text[]`, reproducing the original rule exactly (verified against the
   originals on the examples in their own source).
2. The old function names live in a separate script, `compat/jsonvd_legacy.sql`, installed on demand into
   the caller's schema and implemented on top of `jsonvd`. It keeps the original signatures and the
   original Spanish result messages (`No existe`, `Jsons iguales`, ...), but fixes the bugs.

## Alternatives considered
- **Ship the old names inside the extension** — rejected: pollutes the clean API with `varchar` returns
  and Spanish messages, and forces every user to carry them.
- **Drop backwards compatibility** — rejected: existing systems would need code changes to adopt the
  library.
- **Reproduce the old bugs for exact compatibility** — rejected: the bugs produce wrong data
  (e.g. `'1'` pushed as `true`), which no caller should depend on.

## Consequences
- **Positive:** existing systems migrate by running one script; new users never see the legacy format.
- **Negative / costs:** the compat layer is not managed by `CREATE EXTENSION` (no automatic upgrade or
  `DROP EXTENSION` cascade for those functions); its behavior changes are documented in
  `docs/05-deployment/migration-from-legacy.md`.
- **Open (Human-in-the-Loop):** none.
