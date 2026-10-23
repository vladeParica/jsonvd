# C4 — Context diagram

> **AI-DLC phase:** `02-design`  ·  Level 1 (the system in its environment).

```mermaid
C4Context
    title System context — jsonvd

    Person(dev, "Caller", "Application developer or DBA writing SQL")
    Person(maint, "Maintainer", "Reviews and merges changes, cuts releases")
    Person(contrib, "Contributor", "Proposes changes through pull requests")

    System(jsonvd, "jsonvd", "PostgreSQL extension with JSONB utilities")

    System_Ext(pg, "PostgreSQL 14-18", "Host database that runs the functions")
    System_Ext(app, "Application", "Calls jsonvd functions through SQL")
    System_Ext(gh, "GitHub", "Source, pull requests, CI on every supported version")

    Rel(dev, pg, "Installs with CREATE EXTENSION", "SQL")
    Rel(app, pg, "Runs queries that call jsonvd", "PostgreSQL protocol")
    Rel(pg, jsonvd, "Executes functions in the caller's session")
    Rel(contrib, gh, "Opens pull requests", "HTTPS")
    Rel(maint, gh, "Approves, merges, releases", "HTTPS")
    Rel(gh, jsonvd, "Tests every change")
```

**Notes**
- jsonvd has no runtime of its own: it exists only as functions inside the host database.
- The only trust boundary that matters at runtime is the caller's database session; at development time it
  is GitHub, where only the maintainer can merge ([ADR-0008](../00-project/adr/0008-repository-governance-and-licensing.md)).
