# Threat model — jsonvd extension and compat layer

> **AI-DLC phase:** `02-design`  ·  **Method:** STRIDE + DREAD prioritization
> **Author:** Vlade Párica  ·  **Date:** 2026-10-23

## 1. Scope and assets to protect
- **Caller data** passed to the functions (may contain PII or secrets — see
  [data classification](../00-project/data-classification.md)).
- **Database integrity**: the extension must not let a caller run SQL or gain privileges they do not have.
- **Database availability**: functions must not let a single call exhaust the server.
- **Source integrity**: only reviewed code reaches `main` and `develop`.

## 2. Data-flow diagram
See [`c4-container.md`](../architecture/c4-container.md): caller → (SQL) → `jsonvd` functions, with
documents passed as arguments and results returned to the caller. No other flows exist at runtime.
At development time: contributor → pull request → CI → maintainer review → merge.

## 3. STRIDE analysis
| Category | Threat | Affected component | Mitigation |
|---|---|---|---|
| **S**poofing | A hostile schema earlier in `search_path` shadows an operator or function used inside jsonvd | All functions | Internal calls qualified with `@extschema@`; `pg_catalog` is searched first unless the caller changes it; `SECURITY INVOKER` limits the effect to the caller's own session ([ADR-0006](../00-project/adr/0006-immutable-functions-without-pinned-search-path.md)) |
| **S**poofing | A malicious pull request is merged | Repository | Rulesets: PR + code-owner approval + green CI; only the admin can bypass ([ADR-0008](../00-project/adr/0008-repository-governance-and-licensing.md)) |
| **T**ampering | SQL injection through document values or keys | Core, compat | No SQL built from values; the one `EXECUTE` (`probando_locura`) quotes identifiers with `%I` and passes data with `USING` ([ADR-0003](../00-project/adr/0003-no-dynamic-sql-and-raised-errors.md)) |
| **T**ampering | Fork pull request runs code in CI with repository credentials | CI | Workflow runs from outside contributors need maintainer approval; default token is read-only |
| **R**epudiation | Not applicable: the library performs no actions on behalf of users | — | Auditing is the host database's responsibility |
| **I**nformation disclosure | Document values echoed in error messages end up in server logs | Core, compat | Errors include only paths, positions, types and counts; covered by a test for the compat layer's invalid-JSON error |
| **I**nformation disclosure | Secrets returned to clients inside documents | Caller | `delete_key_deep` provided to strip keys; responsibility stays with the caller |
| **D**enial of service | Very large or deeply nested documents make recursive traversal use a lot of memory and CPU | `_nodes`, `diff`, `merge_deep`, `delete_key_deep` | Bounded by the caller's input; `statement_timeout` and `work_mem` apply; recursion depth bounded by PostgreSQL's `max_stack_depth` for PL/pgSQL |
| **E**levation of privilege | Trusted extension install script used to run code as a privileged role | Install script | Script only creates functions in its own schema; no `SECURITY DEFINER`, no `ALTER`/`GRANT` on other objects |

## 4. DREAD prioritization
| Threat | Damage | Reproducibility | Exploitability | Affected users | Discoverability | Total |
|---|---|---|---|---|---|---|
| DoS via huge or deep documents | 5 | 9 | 6 | 3 | 6 | 29 |
| Values in error messages reach logs (fixed in #2; kept for regressions) | 4 | 2 | 3 | 2 | 4 | 15 |
| `search_path` shadowing of operators | 3 | 4 | 2 | 1 | 3 | 13 |
| Malicious PR merged | 8 | 2 | 2 | 8 | 3 | 23 |
| SQL injection through values | 9 | 1 | 1 | 5 | 2 | 18 |

SQL injection is scored low because there is no code path that executes values; it is listed because it
was the main defect of the legacy procedures.

## 5. Accepted risks / decisions
- **DoS via large documents:** accepted; the library cannot know the caller's limits. Mitigated by
  standard server settings (`statement_timeout`, `max_stack_depth`). Owner: maintainer.
- **`search_path` shadowing:** accepted per [ADR-0006](../00-project/adr/0006-immutable-functions-without-pinned-search-path.md);
  effect limited to the caller's own session.
- **Encryption in transit and at rest:** provided by the host PostgreSQL (TLS, disk encryption); the
  library handles no data outside the server process.
- `<TODO — Human-in-the-Loop: confirm acceptance of the DoS and search_path residual risks>`
