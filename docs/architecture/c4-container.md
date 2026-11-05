# C4 — Container diagram

> **AI-DLC phase:** `02-design`  ·  Level 2 (containers inside the system).
> Drawn as a Mermaid flowchart with C4 styling (see the note in `c4-context.md`).

```mermaid
flowchart TB
    caller["<b>Caller</b><br/><i>[Person]</i><br/>Application or DBA"]

    subgraph db["PostgreSQL database"]
        direction TB
        tables[("<b>Caller tables</b><br/><i>[jsonb columns]</i><br/>The caller's documents")]
        compat["<b>Compat functions</b><br/><i>[SQL script in the caller's schema]</i><br/>Legacy procedure names on top of jsonvd"]
        ext["<b>jsonvd schema</b><br/><i>[Extension, SQL and PL/pgSQL]</i><br/>Path search, diff, merge, inference, legacy paths"]
        catalog[("<b>System catalog</b><br/><i>[pg_catalog]</i><br/>Function definitions, extension metadata")]
    end

    caller -- "Reads and writes documents" --> tables
    caller -- "Calls legacy names" --> compat
    caller -- "Calls jsonvd.* functions" --> ext
    compat -- "Delegates to" --> ext
    ext -- "Registered in" --> catalog

    classDef person fill:#08427B,stroke:#073B6F,color:#fff
    classDef container fill:#438DD5,stroke:#3C7FC0,color:#fff
    classDef store fill:#438DD5,stroke:#3C7FC0,color:#fff
    class caller person
    class compat,ext container
    class tables,catalog store
```

**Notes**
- The extension never reads or writes tables: documents reach it only as arguments.
- The compat functions are created by a plain script, so they are not part of the extension and are not
  removed by `DROP EXTENSION jsonvd` ([ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)).
