# Architecture — jsonvd

> **AI-DLC phase:** `02-design`  ·  **Status:** `accepted`
> **Related ADRs:** [0001](../00-project/adr/0001-package-as-a-postgresql-extension.md),
> [0002](../00-project/adr/0002-pure-sql-and-pl-pgsql-on-jsonb.md),
> [0003](../00-project/adr/0003-no-dynamic-sql-and-raised-errors.md),
> [0004](../00-project/adr/0004-support-postgresql-14-and-later.md),
> [0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md),
> [0006](../00-project/adr/0006-immutable-functions-without-pinned-search-path.md)

## 1. Architectural style
An in-database library: a PostgreSQL extension made of pure functions that run inside the caller's
session ([ADR-0001](../00-project/adr/0001-package-as-a-postgresql-extension.md)). There is no service,
no network interface and no state of its own.

.Tech stack
| Layer | Technology | ADR |
|---|---|---|
| Runtime | PostgreSQL 14–18 | [ADR-0004](../00-project/adr/0004-support-postgresql-14-and-later.md) |
| Language | SQL and PL/pgSQL on `jsonb` | [ADR-0002](../00-project/adr/0002-pure-sql-and-pl-pgsql-on-jsonb.md) |
| Packaging | Extension control file + versioned script, PGXS `Makefile` | [ADR-0001](../00-project/adr/0001-package-as-a-postgresql-extension.md) |
| Legacy support | Plain SQL script (`compat/jsonvd_legacy.sql`) | [ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md) |
| Tests / CI | `pg_regress`, Docker, GitHub Actions | [ADR-0007](../00-project/adr/0007-regression-tests-with-pg-regress-and-docker.md) |

## 2. Main components
All in `sql/jsonvd--1.0.0.sql`, inside the `jsonvd` schema. See the component diagram in
[`docs/architecture/c4-component.md`](../architecture/c4-component.md).

- **Value inference** — `parse_value`, `typeof_text`. Base for every function that accepts text values.
- **Building and modification** — `build_object`, `push` (two overloads), `set_path`, `delete_key_deep`.
- **Merge** — `merge_deep`, `merge_patch`.
- **Traversal** — `_nodes` (internal): a recursive CTE that yields every node with its path and an ordering
  key. Base for `flatten`, `find_path`, `find_paths`, `contains_deep`.
- **Diff** — `diff`: a recursive CTE over pairs of nodes that only descends into sub-documents that differ.
- **Schema inference** — `infer_schema`, `recordset_definition`.
- **Legacy paths** — `legacy_path`, `to_legacy_path`.
- **Compat layer** (separate script) — the legacy procedure names, implemented with the components above.

Every component is stateless. State lives only in the arguments.

## 3. Data model (high level)
The library has no tables. Its data structures are:
- **Path** — `text[]`, compatible with `#>`, `#>>`, `#-` and `jsonb_set`.
- **Ordering key** — `bigint[]` of 1-based ordinals per level, used internally to return nodes in document
  order (array comparison gives pre-order).
- **Diff row** — `(path text[], op text, old_value jsonb, new_value jsonb)`; a missing side is SQL `NULL`,
  distinct from JSON `null`.
- **Legacy path** — `jsonb` array of steps `{"clave": text, "posicion": int}`.

## 4. Access control
- Functions are `SECURITY INVOKER`: they run with the caller's privileges and can only see data the caller
  passes in.
- The extension is `trusted`: a user with `CREATE` on the database can install it without superuser.
- The install script only creates functions in its own schema; every internal call is qualified with
  `@extschema@` ([ADR-0006](../00-project/adr/0006-immutable-functions-without-pinned-search-path.md)).
- Usage is governed by the standard `EXECUTE` privilege on functions (granted to `PUBLIC` by default).

## 5. Quality attributes
- **Security:** no dynamic SQL built from values, errors raised with SQLSTATEs
  ([ADR-0003](../00-project/adr/0003-no-dynamic-sql-and-raised-errors.md)); see the
  [threat model](threat-model.md).
- **Correctness:** comparisons use `jsonb` equality; behavior is pinned by the regression suite on every
  supported version.
- **Performance:** functions are `IMMUTABLE PARALLEL SAFE`; SQL functions can be inlined. Traversal copies
  sub-documents, so memory grows with document size × depth. On a 2,000-object document, `contains_deep`
  ran in ~48 ms vs ~64 ms for the legacy `search_jsonVD`.
- **Portability:** no compiled code; installs on any server with PGXS, or by running the script.
- **Operations:** nothing to run or monitor besides the host database (see `docs/06-monitoring/`).

See the C4 diagrams in `docs/architecture/` for context, containers and components.
