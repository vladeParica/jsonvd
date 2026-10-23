# Contributing

Thanks for your interest in improving jsonvd!

## Workflow

1. Fork the repository and create a branch from `develop`.
2. Make your change, with tests (see below).
3. Open a pull request against `develop`.

`master` holds released code. Every pull request needs a green CI run and the
maintainer's approval before it can be merged.

## Tests

The suite uses `pg_regress`. Each file in `test/sql/` is run and its output is
compared with the matching file in `test/expected/`.

```bash
scripts/test.sh        # with Docker: PostgreSQL 14 to 18
scripts/test.sh 17     # a single version
make installcheck      # with a local PostgreSQL and pg_config on PATH
```

When you add or change behavior, add queries to the relevant `test/sql/*.sql`
file and update `test/expected/*.out` with the new output, after checking it
is correct.

## Guidelines

- Keep functions in `sql/jsonvd--<version>.sql`, inside the `@extschema@` schema.
- No dynamic SQL built from values; raise errors instead of returning them as data.
- Mark pure functions `IMMUTABLE PARALLEL SAFE`.
- Use [Conventional Commits](https://www.conventionalcommits.org/) in English,
  e.g. `feat: add jsonvd.paths_matching`.
