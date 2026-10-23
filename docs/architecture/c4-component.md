# C4 — Component diagram: jsonvd schema

> **AI-DLC phase:** `02-design`  ·  Level 3 (components inside a container).
> Drawn as a Mermaid flowchart with C4 styling (see the note in `c4-context.md`).

```mermaid
flowchart TB
    compat["<b>Compat functions</b><br/><i>[Container: SQL script]</i><br/>Legacy procedure names"]

    subgraph ext["jsonvd schema"]
        direction TB
        build["<b>Building and modification</b><br/><i>[SQL, PL/pgSQL]</i><br/>build_object, push, set_path, delete_key_deep"]
        infer["<b>Value inference</b><br/><i>[PL/pgSQL]</i><br/>parse_value, typeof_text"]
        search["<b>Path search</b><br/><i>[SQL]</i><br/>flatten, find_path, find_paths, contains_deep"]
        nodes["<b>Traversal</b><br/><i>[SQL recursive CTE]</i><br/>_nodes: every node with path and order key"]
        legacy["<b>Legacy paths</b><br/><i>[PL/pgSQL]</i><br/>legacy_path, to_legacy_path"]
        schema["<b>Schema inference</b><br/><i>[SQL]</i><br/>infer_schema, recordset_definition"]
        merge["<b>Merge</b><br/><i>[PL/pgSQL]</i><br/>merge_deep, merge_patch"]
        diff["<b>Diff</b><br/><i>[SQL recursive CTE]</i><br/>diff"]
    end

    compat -- "Uses" --> build
    compat -- "Uses" --> search
    compat -- "Uses" --> legacy
    compat -- "Uses" --> schema
    build -- "Infers text values with" --> infer
    search -- "Walks documents with" --> nodes

    classDef component fill:#85BBF0,stroke:#5D82A8,color:#000
    classDef container fill:#438DD5,stroke:#3C7FC0,color:#fff
    class build,infer,search,nodes,legacy,schema,merge,diff component
    class compat container
```

## Rules / behavior
1. Every function is pure: same input, same output; no table access ([ADR-0006](../00-project/adr/0006-immutable-functions-without-pinned-search-path.md)).
2. No component builds SQL from values ([ADR-0003](../00-project/adr/0003-no-dynamic-sql-and-raised-errors.md)).
3. Traversal returns nodes in document order; search functions inherit that order.
4. Legacy paths follow the last-step rule ([ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)).
5. The compat layer also uses value inference directly; merge and diff have no internal dependencies.
