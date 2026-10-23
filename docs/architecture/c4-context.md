# C4 — Context diagram

> **AI-DLC phase:** `02-design`  ·  Level 1 (the system in its environment).
> Drawn as a Mermaid flowchart with C4 styling: Mermaid's native C4 syntax is experimental and lays out
> poorly on GitHub.

```mermaid
flowchart TB
    contrib["<b>Contributor</b><br/><i>[Person]</i><br/>Proposes changes through pull requests"]
    maint["<b>Maintainer</b><br/><i>[Person]</i><br/>Reviews and merges changes, cuts releases"]
    caller["<b>Caller</b><br/><i>[Person]</i><br/>Application developer or DBA writing SQL"]
    app["<b>Application</b><br/><i>[External system]</i><br/>Calls jsonvd through SQL"]

    gh["<b>GitHub</b><br/><i>[External system]</i><br/>Source, pull requests, CI on every supported version"]
    jsonvd["<b>jsonvd</b><br/><i>[Software system]</i><br/>PostgreSQL extension with JSONB utilities"]
    pg["<b>PostgreSQL 14–18</b><br/><i>[External system]</i><br/>Host database that runs the functions"]

    contrib -- "Opens pull requests" --> gh
    maint -- "Approves, merges, releases" --> gh
    gh -- "Tests and releases" --> jsonvd
    caller -- "Installs with CREATE EXTENSION" --> pg
    app -- "Runs queries that call jsonvd" --> pg
    pg -- "Executes in the caller's session" --> jsonvd

    classDef person fill:#08427B,stroke:#073B6F,color:#fff
    classDef system fill:#1168BD,stroke:#0B4884,color:#fff
    classDef external fill:#999999,stroke:#8A8A8A,color:#fff
    class contrib,maint,caller person
    class jsonvd system
    class gh,pg,app external
```

**Notes**
- jsonvd has no runtime of its own: it exists only as functions inside the host database.
- The only trust boundary that matters at runtime is the caller's database session; at development time it
  is GitHub, where only the maintainer can merge ([ADR-0008](../00-project/adr/0008-repository-governance-and-licensing.md)).
