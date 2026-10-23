# Gate 2 — Implementation → Testing

> **AI-DLC phase:** exit of `03-implementation`.
> **Goal:** confirm the build matches the agreed design and is ready to be tested seriously.

## Build vs design
- [ ] Implemented behavior matches `docs/02-design/` (or the divergence is captured in a new/updated ADR).
- [ ] `docs/03-implementation/backlog.md` reflects what's built and what's left.
- [ ] Data model / migrations match the design's data model.

## Quality basics
- [ ] Code builds and type-checks / lints clean.
- [ ] Security controls from the threat model are actually implemented (auth, encryption, audit, access control).
- [ ] Secrets are out of the repo; config is externalized.

## Docs in sync
- [ ] Contracts/API docs updated to match the running endpoints (or the generated spec is the source of truth).
- [ ] Implementation notes capture anything non-obvious a maintainer would need.

## Verdict
- [ ] **Gate 2 passed** — cleared to enter `04-testing`.
- Approved by: `<TODO>`  ·  Date: `<TODO>`

## Evidence (prepared for review — not approval)
- Backlog, implementation notes and deviations (none): `docs/03-implementation/backlog.md`.
- No tables or migrations: the data model is in-memory structures (architecture §3).
- Security controls implemented: no dynamic SQL on values, raised errors, no `SECURITY DEFINER` (`sql/jsonvd--1.0.0.sql`).
- No secrets or configuration exist.
- Known open item: `convert_array_jsonVD` echoes the input fragment in an error (backlog).
