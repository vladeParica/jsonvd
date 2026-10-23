# Gate 1 — Design → Implementation

> **AI-DLC phase:** exit of `02-design`.
> **Goal:** confirm architecture, threat model and key decisions (ADRs) are complete before writing code.

## Architecture
- [ ] `docs/02-design/architecture.md` describes style, layers and the data model.
- [ ] C4 diagrams present and valid (Mermaid):
  - [ ] `docs/architecture/c4-context.md`
  - [ ] `docs/architecture/c4-container.md`
  - [ ] `docs/architecture/c4-component-*.md` (per key container)
- [ ] Any critical design property is explicit (e.g. deterministic vs ML, stateless vs stateful).

## Security
- [ ] `docs/02-design/threat-model.md` applies STRIDE to the main components.
- [ ] Threats prioritized with DREAD; cover data exposure, spoofing, DoS, data loss.
- [ ] Encryption in transit and at rest for sensitive data is confirmed as a requirement, not an option.

## Contracts
- [ ] `docs/02-design/api-contracts.md` lists the endpoints.
- [ ] The API contract (design and/or generated spec) is valid and coherent.

## Decisions (ADR)
- [ ] Every non-trivial decision has an ADR in the standard format (Context / Decision / Alternatives / Consequences).
- [ ] Open decisions still marked `<TODO — Human-in-the-Loop>`.

## Verdict
- [ ] **Gate 1 passed** — cleared to enter `03-implementation`.
- Approved by: `<TODO>`  ·  Date: `<TODO>`

## Evidence (prepared for review — not approval)
- Architecture and data structures: `docs/02-design/architecture.md`.
- C4: `docs/architecture/c4-context.md`, `c4-container.md`, `c4-component.md` (one key container: the `jsonvd` schema).
- Critical property: every function is pure and deterministic (`IMMUTABLE`) — ADR-0006.
- Threat model with STRIDE + DREAD: `docs/02-design/threat-model.md`. Encryption is the host database's responsibility (the library stores no data).
- Contracts: `docs/02-design/api-contracts.md` (SQL functions; source of truth is `sql/jsonvd--1.0.0.sql`).
- ADRs 0001–0009 in `docs/00-project/adr/`.
