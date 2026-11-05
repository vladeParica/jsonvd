# Gate 1 — Design → Implementation

> **AI-DLC phase:** exit of `02-design`.
> **Goal:** confirm architecture, threat model and key decisions (ADRs) are complete before writing code.

## Architecture
- [x] `docs/02-design/architecture.md` describes style, layers and the data model.
- [x] C4 diagrams present and valid (Mermaid) — rendered without errors with `@mermaid-js/mermaid-cli` 11.4.2:
  - [x] `docs/architecture/c4-context.md`
  - [x] `docs/architecture/c4-container.md`
  - [x] `docs/architecture/c4-component.md` (the one key container: the `jsonvd` schema)
- [x] Any critical design property is explicit (e.g. deterministic vs ML, stateless vs stateful). *(pure, `IMMUTABLE`, stateless — ADR-0006)*

## Security
- [x] `docs/02-design/threat-model.md` applies STRIDE to the main components.
- [x] Threats prioritized with DREAD; cover data exposure, spoofing, DoS, data loss. *(data loss: the library stores no data)*
- [x] Encryption in transit and at rest for sensitive data is confirmed as a requirement, not an option. *(provided by the host PostgreSQL; the library keeps no data outside the server process)*

## Contracts
- [x] `docs/02-design/api-contracts.md` lists the endpoints. *(SQL functions)*
- [x] The API contract (design and/or generated spec) is valid and coherent. *(source of truth: `sql/jsonvd--1.0.0.sql`; behavior pinned by `test/expected/`)*

## Decisions (ADR)
- [x] Every non-trivial decision has an ADR in the standard format (Context / Decision / Alternatives / Consequences).
- [x] Open decisions still marked `<TODO — Human-in-the-Loop>`.

## Verdict
- [x] **Gate 1 passed** — cleared to enter `03-implementation`. **Passed (retroactive):** the design was
  documented after the 1.0.0 implementation; residual risks accepted in #10.
- Approved by: Vlade Párica (#11)  ·  Date: 2026-10-23

## Evidence (prepared for review — not approval)
- Architecture and data structures: `docs/02-design/architecture.md`.
- C4: `docs/architecture/c4-context.md`, `c4-container.md`, `c4-component.md` (one key container: the `jsonvd` schema).
- Critical property: every function is pure and deterministic (`IMMUTABLE`) — ADR-0006.
- Threat model with STRIDE + DREAD: `docs/02-design/threat-model.md`. Encryption is the host database's responsibility (the library stores no data).
- Contracts: `docs/02-design/api-contracts.md` (SQL functions; source of truth is `sql/jsonvd--1.0.0.sql`).
- ADRs 0001–0009 in `docs/00-project/adr/`.
