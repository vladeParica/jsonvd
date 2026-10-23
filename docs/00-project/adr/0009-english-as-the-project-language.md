# ADR-0009 — English as the project language

> **AI-DLC phase:** `00-project`  ·  **Status:** `accepted`
> **Date:** 2026-10-23  ·  **Owner:** Vlade Párica

## Context
The original procedures, comments and messages were in Spanish. The goal of publishing the library is to
reach as many PostgreSQL users as possible.

## Decision
Code, comments, error messages, tests, commit messages and documentation are in English. Three things
stay in Spanish on purpose:
- `legacy/` — the original code, kept unchanged for reference.
- The legacy path keys `clave` and `posicion` — they are part of the callers' data format.
- The result messages of the compat layer (`No existe`, `Jsons iguales`, ...) — existing callers compare
  against them ([ADR-0005](0005-preserve-legacy-path-semantics-with-a-separate-compat-layer.md)).

## Alternatives considered
- **Spanish** — rejected: narrows the audience.
- **Bilingual docs** — rejected for now: doubles the maintenance cost of every document.

## Consequences
- **Positive:** accessible to the wider PostgreSQL community.
- **Negative / costs:** legacy-format identifiers in English docs need a gloss (see
  `docs/00-project/glossary.md`).
- **Open (Human-in-the-Loop):** none.
