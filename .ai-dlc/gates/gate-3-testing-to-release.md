# Gate 3 — Testing → Release

> **AI-DLC phase:** exit of `04-testing` (with `05-deployment` / `06-monitoring` ready).
> **Goal:** confirm the system is tested, deployable and observable before going live.

## Testing
- [x] `docs/04-testing/` has a test strategy and it was executed (unit/integration/e2e as applicable). *(CI on every PR, PostgreSQL 14–18)*
- [x] Critical/safety paths and the abuse scenarios from the PRD are covered.
- [x] Known gaps are listed with a decision (fix now vs accept).

## Deployment
- [x] `docs/05-deployment/` has a step-by-step deploy guide and a runbook.
- [x] Environment variables/secrets documented; secret generation covered. *(none at runtime; release secrets `PGXN_USERNAME` / `PGXN_PASSWORD` documented)*
- [ ] Backups/rollback strategy defined and tested (if data matters). *(defined; not testable until a second version exists — upgrade/rollback scripts come with #7. The library stores no data.)*

## Monitoring
- [x] `docs/06-monitoring/` defines the key metrics, alerts and SLOs.
- [x] Health checks exist and are documented. *(`jsonvd.version()`, `pg_extension`)*

## Compliance / sign-off
- [x] Data-classification obligations (retention, audit, encryption) are met or the debt is explicit. *(log-leak exception fixed in #2)*
- [x] Remaining `<TODO — Human-in-the-Loop>` items are resolved or consciously deferred. *(deferred as issues in milestone v1.1.0)*

## Verdict
- [x] **Gate 3 passed** — cleared to release. **Conditionally passed (retroactive; 1.0.0 already released):**
  upgrade and rollback will be tested with the first upgrade script (#7).
- Approved by: Vlade Párica (#11)  ·  Date: 2026-10-23

## Evidence (prepared for review — not approval)
- Test strategy and coverage map: `docs/04-testing/test-strategy.md`; suite passing on PostgreSQL 14–18 in CI.
- Abuse scenarios from the PRDs covered in `test/sql/*.sql`; known gaps listed with decisions.
- Install, upgrade, rollback, uninstall and release process: `docs/05-deployment/deploy-guide.md`; migration: `migration-from-legacy.md`.
- No environment variables or secrets; no data to back up.
- Monitoring (function statistics, CI health): `docs/06-monitoring/monitoring.md`.
