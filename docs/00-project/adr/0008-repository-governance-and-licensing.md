# ADR-0008 — Repository governance and licensing

> **AI-DLC phase:** `00-project`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
The project is being opened to outside contributors. The owner wants to review and be the only one who
can approve and merge changes. The repository had no license, which legally prevents anyone else from
using the code.

## Decision
- **License:** MIT.
- **Branches:** `main` holds released code; `develop` is the integration branch and the target for
  contributor pull requests.
- **Rulesets on `main` and `develop`:** changes only through pull requests, one approving review from the
  code owner, green CI on every supported PostgreSQL version, resolved review threads, no force-push, no
  deletion. Only the repository admin role can bypass.
- **`.github/CODEOWNERS`** assigns the owner as reviewer of every file.
- **GitHub Actions:** workflows from fork pull requests need the owner's approval for every outside
  contributor; the default workflow token is read-only.

## Alternatives considered
- **PostgreSQL License** — equally permissive and common for extensions; MIT was chosen as the most widely
  recognized license.
- **Single `main` branch** — rejected: contributor changes would land directly in released code.

## Consequences
- **Positive:** anyone can use and contribute to the code; nothing reaches `main` or `develop` without the
  owner's review and a green CI.
- **Negative / costs:** every change, including the owner's, goes through a pull request unless the admin
  bypass is used; releases need a `develop` → `main` pull request.
- **Open (Human-in-the-Loop):** none.
