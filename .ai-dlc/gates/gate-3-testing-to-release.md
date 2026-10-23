# Gate 3 — Testing → Release

> **AI-DLC phase:** exit of `04-testing` (with `05-deployment` / `06-monitoring` ready).
> **Goal:** confirm the system is tested, deployable and observable before going live.

## Testing
- [ ] `docs/04-testing/` has a test strategy and it was executed (unit/integration/e2e as applicable).
- [ ] Critical/safety paths and the abuse scenarios from the PRD are covered.
- [ ] Known gaps are listed with a decision (fix now vs accept).

## Deployment
- [ ] `docs/05-deployment/` has a step-by-step deploy guide and a runbook.
- [ ] Environment variables/secrets documented; secret generation covered.
- [ ] Backups/rollback strategy defined and tested (if data matters).

## Monitoring
- [ ] `docs/06-monitoring/` defines the key metrics, alerts and SLOs.
- [ ] Health checks exist and are documented.

## Compliance / sign-off
- [ ] Data-classification obligations (retention, audit, encryption) are met or the debt is explicit.
- [ ] Remaining `<TODO — Human-in-the-Loop>` items are resolved or consciously deferred.

## Verdict
- [ ] **Gate 3 passed** — cleared to release.
- Approved by: `<TODO>`  ·  Date: `<TODO>`

## Evidence (prepared for review — not approval)
- Test strategy and coverage map: `docs/04-testing/test-strategy.md`; suite passing on PostgreSQL 14–18 in CI.
- Abuse scenarios from the PRDs covered in `test/sql/*.sql`; known gaps listed with decisions.
- Install, upgrade, rollback, uninstall and release process: `docs/05-deployment/deploy-guide.md`; migration: `migration-from-legacy.md`.
- No environment variables or secrets; no data to back up.
- Monitoring (function statistics, CI health): `docs/06-monitoring/monitoring.md`.
