# Security policy

## Supported versions

| Version | Supported |
|---|---|
| 1.0.x | ✅ |

Supported PostgreSQL versions follow [ADR-0010](docs/00-project/adr/0010-track-upstream-supported-postgresql-versions.md).

## Reporting a vulnerability

**Please do not open a public issue.** Report it privately through
[GitHub private vulnerability reporting](https://github.com/vladeParica/jsonvd/security/advisories/new).

Include the PostgreSQL version, the jsonvd version, and a query that reproduces the problem. Please use
synthetic data: do not send real personal data or secrets.

## What to expect

- Acknowledgement within **7 days**.
- An assessment and, if confirmed, a fix plan within **30 days**.
- Credit in the release notes, unless you prefer to stay anonymous.

## Scope

In scope: the `jsonvd` extension (`sql/`) and the compat layer (`compat/`) — for example SQL injection,
privilege escalation, data disclosure through error messages, or denial of service with small inputs.
The design-level threats and accepted risks are documented in the
[threat model](docs/02-design/threat-model.md).

Out of scope: the historical procedures in `legacy/`, which are kept for reference and not installed.
