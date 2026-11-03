---
name: impact-analysis
description: Trace everything a change touches across every repo before work starts (callers, routes, database schema and queries, background jobs, events, config and flags, API consumers, UI, tests, docs) and report each finding with a file and line. Use before building a ticket, before changing a table, field, endpoint or shared function, when a change "touches the other repo", or when someone asks "what will this break?" or "what uses this?".
---

# Impact Analysis

Find the blast radius before writing code, not after the deploy. The output is a short report the dev and the reviewer can trust.

## Step 0: Read the stack

For each repo in scope, check the manifest (`package.json`, `pyproject.toml`, `go.mod`, `Gemfile`, `pom.xml`, ...) and the folder layout so you know where routes, models, migrations, jobs and tests live. Search with `rg -n` (or `git grep -n`), skipping `node_modules`, `vendor`, build output and lockfiles.

## Step 1: Pin down what's changing

Get the concrete names: tables, columns, model or type names, endpoint paths, response fields, functions and classes, jobs, event or topic names, env vars, flags. Read them from the ticket or PRD, or ask. Vague input ("the billing stuff") gives a vague report, so push for names.

## Step 2: Find all the repos

Read the repo map (`repo-map.md` in the parent folder, or `docs/repo-map.md`) for sibling repos and who consumes what, and verify it against the code. No map: treat every git repo next to this one as in scope, and suggest `repo-map` afterwards.

## Step 3: Trace

Search every repo, not just this one. Search each name in all its forms (`snake_case`, `camelCase`, `PascalCase`, `kebab-case`, URL path); serializers and frontend clients often rename fields.

- **Callers and imports.** `rg -n "\bvoidInvoice\b|void_invoice"`, plus the module's import path. Watch for re-exports, DI registrations, and calls by string name (reflection, `getattr`, `send`).
- **Routes and handlers.** The route table (`routes/`, `urls.py`, `config/routes.rb`, router files, controller annotations) and any middleware or guards on the path. `rg -n "/invoices"`.
- **Database schema and queries.** The schema or model file (`schema.prisma`, ORM models, entity structs), migrations, raw SQL (`rg -n "invoices\b" -g "*.sql"` and SQL strings in code), query builders, views, triggers, indexes and constraints on the column.
- **Background jobs.** Cron entries, scheduler config, queue workers: `rg -n` for the job name and for the table or field inside worker code. Jobs queued by the old code can still run during the deploy.
- **Events and queues.** Producers and consumers of any payload that carries the field: topic or queue names, webhook payloads, outbox tables. Consumers often live in other repos.
- **Config and feature flags.** Env vars (`.env.example`, deploy manifests, CI), settings files, flag names in code and in the flag service.
- **Public API and SDK consumers.** OpenAPI/GraphQL/proto files, generated clients, published SDKs, partner integrations, mobile apps that can't be force-updated.
- **UI that renders the data.** Components, pages, forms, tables, exports and emails that show it; `switch`/`match` on enum values with no default case.
- **Tests.** Tests that cover it, fixtures and factories that build it, snapshots and contract tests. Note what has no coverage.
- **Docs.** README, API docs, runbooks and ADRs that describe the current behavior.

**Data.** Row counts of affected tables if the dev can get them (they matter for migrations), and existing rows that would break a new constraint.

## Step 4: Report

Write it in chat, and append it to the PRD or ticket file if there is one:

```markdown
## Impact: add `void` status to invoices

Risk: Medium (nightly export and the web app both branch on status)

### Direct
- api/src/billing/invoice.model.ts:88 status enum, add `void`
- api/src/billing/invoice.serializer.ts:30 exposes status

### Indirect
- api/src/jobs/nightly-export.ts:112 filters status IN (...), `void` rows dropped silently
- api/src/billing/events.ts:20 emits invoice.status_changed; notifications emails on it (wanted? ask)

### Other repos
- web/src/api/invoices.ts:14 switch on status with no default, UI breaks on `void`
- reporting reads the invoices table directly (repo map: Shared DB)

### Data
- invoices ~2M rows. Adding nullable columns is safe.

### Tests
- Covered: api/test/billing/invoice-api.test.ts
- Not covered: nightly export, status event → characterization-tests first

### Unverified
- README mentions a BI dashboard on invoices.status; no code found

### Recommended route
characterization-tests → safe-change → db-migrations → cross-repo-change
```

## Rules

- Every finding has a file and line. Suspected but not found goes under "Unverified", not dropped.
- Search every name in all its casings and as a URL path.
- Don't fix anything here. This skill only reports.
