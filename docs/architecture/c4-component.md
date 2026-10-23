# C4 — Component diagram: jsonvd schema

> **AI-DLC phase:** `02-design`  ·  Level 3 (components inside a container).

```mermaid
C4Component
    title Components — jsonvd schema

    Container_Boundary(ext, "jsonvd schema") {
        Component(infer, "Value inference", "PL/pgSQL", "parse_value, typeof_text")
        Component(build, "Building and modification", "SQL, PL/pgSQL", "build_object, push, set_path, delete_key_deep")
        Component(merge, "Merge", "PL/pgSQL", "merge_deep, merge_patch")
        Component(nodes, "Traversal", "SQL recursive CTE", "_nodes: every node with path and order key")
        Component(search, "Path search", "SQL", "flatten, find_path, find_paths, contains_deep")
        Component(diff, "Diff", "SQL recursive CTE", "diff")
        Component(schema, "Schema inference", "SQL", "infer_schema, recordset_definition")
        Component(legacy, "Legacy paths", "PL/pgSQL", "legacy_path, to_legacy_path")
    }

    Container(compat, "Compat functions", "SQL script", "Legacy procedure names")

    Rel(build, infer, "Infers text values with")
    Rel(search, nodes, "Walks documents with")
    Rel(compat, build, "Uses")
    Rel(compat, search, "Uses")
    Rel(compat, legacy, "Uses")
    Rel(compat, schema, "Uses")
    Rel(compat, infer, "Uses")
```

## Rules / behavior
1. Every function is pure: same input, same output; no table access ([ADR-0006](../00-project/adr/0006-immutable-functions-without-pinned-search-path.md)).
2. No component builds SQL from values ([ADR-0003](../00-project/adr/0003-no-dynamic-sql-and-raised-errors.md)).
3. Traversal returns nodes in document order; search functions inherit that order.
4. Legacy paths follow the last-step rule ([ADR-0005](../00-project/adr/0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)).
