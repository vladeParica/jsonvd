# Deployment guide — jsonvd

> **AI-DLC phase:** `05-deployment`
> jsonvd is installed into an existing PostgreSQL database. There are no services to run and no secrets.

## 1. Requirements
| Requirement | For | Notes |
|---|---|---|
| PostgreSQL 14–18 | Runtime | [ADR-0004](../00-project/adr/0004-support-postgresql-14-and-later.md) |
| `pg_config` + PGXS (`postgresql-server-dev-<version>` on Debian/Ubuntu) | `make install` | Not needed for the script fallback |
| `CREATE` privilege on the database | `CREATE EXTENSION` | The extension is `trusted`: superuser not required |

## 2. Configuration
jsonvd has no settings and no environment variables. Relevant server settings:

| Setting | Use |
|---|---|
| `statement_timeout` | Bounds the time of calls on very large documents ([threat model](../02-design/threat-model.md)) |
| `track_functions = 'pl'` | Optional: per-function call statistics (see `06-monitoring`) |

## 3. Install
```bash
git clone https://github.com/vladeParica/jsonvd
cd jsonvd
make install                      # copies jsonvd.control and the SQL script into the server's extension dir
```
```sql
CREATE EXTENSION jsonvd;          -- creates the jsonvd schema
SELECT jsonvd.version();          -- smoke test: 1.0.0
```

### Managed databases (RDS, Cloud SQL, …)
These only allow allow-listed extensions. Install the functions as a plain script instead:
```bash
sed -e 's/@extschema@/jsonvd/g' -e '/^.echo /d' sql/jsonvd--1.0.0.sql > jsonvd-install.sql
psql -d mydb -c 'CREATE SCHEMA jsonvd' -f jsonvd-install.sql
```
Objects installed this way are not tracked as an extension: upgrade by re-running the new script after
dropping the schema (`DROP SCHEMA jsonvd CASCADE` — this also drops dependent objects, check first).

### Compat layer (optional)
Only for systems that call the legacy procedure names — see the
[migration guide](migration-from-legacy.md):
```bash
psql -d mydb -f compat/jsonvd_legacy.sql
```

## 4. Upgrade, rollback, uninstall
- **Upgrade:** each new version ships `sql/jsonvd--<old>--<new>.sql`; after `make install`, run
  `ALTER EXTENSION jsonvd UPDATE;`. (1.0.0 is the first version; there are no upgrade scripts yet.)
- **Rollback:** reinstall the previous version's files and run `ALTER EXTENSION jsonvd UPDATE TO '<old>'`
  if a downgrade script exists; otherwise `DROP EXTENSION` and `CREATE EXTENSION ... VERSION '<old>'`.
- **Uninstall:** `DROP EXTENSION jsonvd;` — fails if other objects depend on its functions (expression
  indexes, views, compat functions); `CASCADE` drops them too. The compat functions are not part of the
  extension and must be dropped separately.
- **Data:** jsonvd stores no data, so there is nothing to back up or restore.

## 5. Release process (maintainer)
1. Merge the release changes into `develop` through pull requests (green CI, approval).
2. On a `release/v<version>` branch: update `default_version` in `jsonvd.control`, `version` (twice) in
   `META.json`, `version()`, add `sql/jsonvd--<old>--<new>.sql` (and keep the full script for fresh
   installs), and rename the `CHANGELOG.md` section `## Unreleased` to `## <version> — YYYY-MM-DD`.
   Changes that do not touch `sql/` or `compat/` (docs, CI, metadata) do not need a new version; they wait
   under `Unreleased` for the next one.
3. Open a pull request `release/v<version>` → `main`; merge after CI passes, then back-merge `main` into
   `develop` with another pull request.
4. Tag `v<version>` on `main` and push the tag. The `Release` workflow then:
   - checks that the tag matches `jsonvd.control`, `META.json` and the SQL script,
   - builds the PGXN bundle (`jsonvd-<version>.zip`; `.gitattributes` leaves dev-only folders out),
   - creates the GitHub release with the changelog entry and the bundle attached,
   - publishes to PGXN **only if** the repository secrets `PGXN_USERNAME` and `PGXN_PASSWORD` exist.
5. `<TODO — Human-in-the-Loop: create a PGXN account, request the jsonvd distribution name and add the two secrets to enable PGXN publishing (#8)>`

## 6. Go-live checklist
- [ ] CI green on every supported PostgreSQL version
- [ ] `CHANGELOG.md` and `version()` updated  · [ ] Upgrade script present (if not the first version)
- [ ] `CREATE EXTENSION` and `ALTER EXTENSION ... UPDATE` tried on a clean database
- [ ] Release tagged on `main`
