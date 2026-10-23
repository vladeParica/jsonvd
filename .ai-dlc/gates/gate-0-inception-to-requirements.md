# Gate 0 — Inception → Requirements

> **AI-DLC phase:** exit of `00-project` and `01-requirements`.
> **Goal:** confirm the problem, scope and core flow are defined and agreed *before* investing in design.

Tick each item only when it is genuinely complete and reviewed by a person.

## Charter and domain
- [ ] `docs/00-project/charter.md` complete: vision, context, problem, scope in/out, metrics, risks.
- [ ] `docs/00-project/glossary.md` defines the ubiquitous language and is consistent across docs.
- [ ] `docs/00-project/data-classification.md` inventories data by sensitivity.
- [ ] Any status/risk taxonomy the domain needs is agreed.

## Requirements
- [ ] `docs/01-requirements/` describes the core flow(s) end to end (a PRD per major flow).
- [ ] Abuse / edge / risk scenarios documented (not just the happy path).
- [ ] Non-negotiable principles made explicit.
- [ ] Acceptance criteria are verifiable.

## Open decisions (Human-in-the-Loop)
- [ ] Owner/client decisions marked `<TODO — Human-in-the-Loop>` and NOT invented.

## Verdict
- [ ] **Gate 0 passed** — cleared to enter `02-design`.
- Approved by: `<TODO>`  ·  Date: `<TODO>`

## Evidence (prepared for review — not approval)
- Charter, glossary, data classification: `docs/00-project/`.
- PRDs with edge/abuse scenarios and acceptance criteria linked to tests: `docs/01-requirements/`.
- Non-negotiables: charter, *Principles*; ADR-0003, ADR-0006.
- Open owner decisions are marked `<TODO — Human-in-the-Loop>` in the charter and PRDs (`lint.mjs` lists them).
- Note: this gate is being run retroactively — version 1.0.0 was built before the docs were written.
