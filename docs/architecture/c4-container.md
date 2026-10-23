# C4 — Container diagram

> **AI-DLC phase:** `02-design`  ·  Level 2 (containers inside the system).

```mermaid
C4Container
    title Containers — jsonvd inside a PostgreSQL database

    Person(caller, "Caller", "Application or DBA")

    System_Boundary(db, "PostgreSQL database") {
        Container(ext, "jsonvd schema", "Extension, SQL and PL/pgSQL", "Path search, diff, merge, inference, legacy paths")
        Container(compat, "Compat functions", "SQL script in the caller's schema", "Legacy procedure names on top of jsonvd")
        ContainerDb(catalog, "System catalog", "pg_catalog", "Function definitions, extension metadata")
        ContainerDb(tables, "Caller tables", "jsonb columns", "The caller's documents")
    }

    Rel(caller, ext, "Calls jsonvd.* functions", "SQL")
    Rel(caller, compat, "Calls legacy names", "SQL")
    Rel(compat, ext, "Delegates to")
    Rel(caller, tables, "Reads and writes documents", "SQL")
    Rel(ext, catalog, "Registered in")
```

**Notes**
- The extension never reads or writes tables: documents reach it only as arguments.
- The compat functions are created by a plain script, so they are not part of the extension and are not
  removed by `DROP EXTENSION jsonvd` ([ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)).
