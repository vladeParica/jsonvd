# Data classification — jsonvd

> **AI-DLC phase:** `00-project`
> jsonvd is a library: it stores no data of its own. It processes the caller's documents in memory, inside
> the caller's session, with the caller's privileges. The classification below is about what it touches
> and where that data could leak.

| Data | Category | Sensitivity | Handling requirements |
|---|---|---|---|
| Documents passed to functions | Caller data (may contain PII or secrets) | Up to Restricted — set by the caller | Never persisted or logged by the library; processed in the caller's session only |
| Values echoed in error messages | Caller data | Up to Restricted | Error messages must not include document values. Paths and type names are allowed. See exception below |
| Extension objects (functions, comments) | Code | Public | Installed in the `jsonvd` schema; no secrets |
| Test fixtures (`test/`) | Synthetic sample data | Public | Must not contain real personal data |
| `legacy/` examples | Historical sample data | Internal | Kept unchanged; contains only a private LAN IP address (`192.168.0.200`) and sample records |

**Sensitivity levels:** `Public` < `Internal` < `Confidential` < `Restricted`.

## Cross-cutting requirements
- The library must not write to tables, logs or files ([ADR-0006](adr/0006-immutable-functions-without-pinned-search-path.md): functions are `IMMUTABLE`).
- Error messages reach the server log (`log_min_messages`), so they must not carry document content.
  - **Known exception:** `convert_array_jsonVD` in the compat layer includes the invalid JSON fragment in
    its error (`invalid JSON: %`). Tracked in `docs/03-implementation/backlog.md`.
- `delete_key_deep` is the recommended way to strip secret keys (e.g. `password`) before returning
  documents to clients.
