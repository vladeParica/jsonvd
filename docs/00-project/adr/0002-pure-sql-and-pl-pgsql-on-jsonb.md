# ADR-0002 — Pure SQL and PL/pgSQL on jsonb

> **AI-DLC phase:** `02-design`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
The legacy functions took and returned `json`/`varchar`, round-tripping through text at every level
(re-parsing the document repeatedly) and returning a mix of JSON, messages and `{"ERROR": ...}` objects
as `varchar`. PostgreSQL's `jsonb` type stores a parsed binary form, supports equality and containment,
and is what the native functions (`jsonb_set`, `#>`, jsonpath) are built around.

## Decision
Every public function takes and returns `jsonb` (or `text[]` / `boolean` / sets where natural) and is
written in plain SQL or PL/pgSQL. No C code.

## Alternatives considered
- **Keep `json`** — rejected: no equality operator, keeps whitespace and duplicate keys, re-parsed on each
  operation.
- **C extension** — rejected for now: needs a compiler per platform and server version, cannot run on
  managed databases, and the current workloads do not need it. Revisit only if profiling shows a hot path
  that SQL cannot serve (see `docs/04-testing/test-strategy.md`, known gaps).
- **PL/Python or PL/v8** — rejected: untrusted or rarely available languages; adds a runtime dependency.

## Consequences
- **Positive:** installs anywhere PostgreSQL runs, readable by any DBA, SQL functions can be inlined by the
  planner, `jsonb` equality makes comparisons correct regardless of whitespace and key order.
- **Negative / costs:** recursive traversal in SQL copies sub-documents, so very large or very deep
  documents cost more memory than a C implementation would; `jsonb` does not preserve the original key
  order, so outputs are in `jsonb` order.
- **Open (Human-in-the-Loop):** none.
