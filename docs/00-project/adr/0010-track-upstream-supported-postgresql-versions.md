# ADR-0010 — Track upstream-supported PostgreSQL versions

> **AI-DLC phase:** `00-project`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica
> **Supersedes:** [ADR-0004](0004-support-postgresql-14-and-later.md) from version 1.1.0.

## Context
[ADR-0004](0004-support-postgresql-14-and-later.md) fixed the minimum at PostgreSQL 14 and left open what to
do when 14 reaches upstream end of life on November 12, 2026 (#6). A fixed minimum forces the same decision
every year, when each major version leaves support. The code uses nothing specific to 14–18, so keeping an
old version costs only CI time.

## Decision
1. **1.0.x** supports PostgreSQL 14–18, as released.
2. **From 1.1.0**, jsonvd supports and tests every PostgreSQL major version that has upstream support at
   the time of the release. A version that reaches end of life is dropped in the next minor release, not
   in a patch release.
3. Dropping PostgreSQL 14 is tracked in #20.

## Alternatives considered
- **Drop 14 right at end of life** — rejected: would change the supported versions between releases, with no
  technical need.
- **Keep 14 indefinitely** — rejected: testing versions without security fixes signals support we cannot
  back up, and grows the CI matrix every year.

## Consequences
- **Positive:** no yearly decision; the supported range is predictable and matches PostgreSQL's own policy.
- **Negative / costs:** each minor release must check the PostgreSQL versioning page and update the CI
  matrix, the rulesets' required checks and the docs.
- **Open (Human-in-the-Loop):** none.
