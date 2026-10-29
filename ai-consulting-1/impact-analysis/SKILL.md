---
name: impact-analysis
description: Trace everything a change touches across all repos before work starts — models, fields, endpoints, serializers, Celery tasks, signals, consumers in other repos, tests and data. Use before building a ticket, before changing a model or endpoint, when a change "touches the other repo", or when someone asks "what will this break?".
---

# Impact Analysis

Find the blast radius before writing code, not after the deploy. Output is a short report the dev (and the reviewer) can trust.

## Step 1: Pin down what's changing

Get the concrete list of things being changed: model names, field names, endpoint paths, serializer fields, function or task names, settings, env vars. Read them from the ticket/PRD, or ask the dev. Vague input ("the billing stuff") gives a vague report, so push for names.

## Step 2: Find all the repos

Read the repo map (`../repo-map.md` or `docs/repo-map.md`). It lists sibling repos and who consumes what. If there's no map, list the sibling folders of the current repo and treat every git repo there as in scope, then suggest running `repo-map` afterwards.

## Step 3: Trace

Search every repo, not just the current one. For each changed thing, look for:

**Inside the Django repo**
- Direct references: `grep -rn "<ModelName>\|<field_name>"` across `*.py`, templates, and fixtures.
- ORM lookups that use the field through relations: `__<field_name>`, `<related_name>__`, `values("…")`, `order_by("…")`, `F("…")`.
- Serializers that expose it (including `fields = "__all__"` which exposes it implicitly).
- Signals: `post_save`/`pre_save`/`m2m_changed` receivers on the model, and `save()` overrides.
- Celery tasks, management commands, cron jobs that read or write it.
- Admin (`list_display`, `list_filter`, `search_fields`), forms, filters (`django-filter` FilterSets).
- Raw SQL and `.extra()` referencing the column.
- Migrations and data migrations that reference it.
- Tests that cover it, and tests that should but don't.

**Outside the repo**
- Frontend and mobile repos: the endpoint path and the JSON field names (`grep -rn "void_reason\|/invoices/"`).
- Other services: HTTP clients calling the endpoint, shared DB reads (reporting, ETL, BI), webhooks, message queue payloads.
- Infra: env vars, settings, feature flags, cron schedules.

**Data**
- Row count of affected tables if you can get it (ask the dev, or check a dev DB). Matters for migrations.
- Existing rows that won't satisfy a new constraint.

## Step 4: Report

Write the report in chat, and append it to the PRD or ticket file if there is one:

```markdown
## Impact: <change in one line>

Risk: Low | Medium | High  (why in one line)

### Direct
- backend/billing/models.py:88 Invoice.status — add `void` choice
- backend/billing/serializers.py:30 InvoiceSerializer exposes status

### Indirect
- backend/reports/tasks.py:112 nightly export filters status__in=[...] — `void` rows will be dropped silently
- signal billing/signals.py:20 sends email on status change — will fire on void (wanted? ask)

### Other repos
- web-app/src/api/invoices.ts:14 switches on status, no default case → UI breaks on `void`
- reporting-service reads billing_invoice directly (repo map §Shared DB)

### Data
- billing_invoice ~2M rows. Adding nullable columns is safe.

### Tests
- Covered: billing/tests/test_invoice_api.py
- Not covered: reports export, the status signal → characterization-tests before touching

### Recommended route
characterization-tests (reports export) → safe-change → django-migrations → cross-repo-change
```

## Rules

- Every finding has a file and line. If you suspect something but can't find it, list it under "Unverified" rather than dropping it.
- Search for the snake_case, camelCase and URL forms of names; frontend code often renames fields.
- Don't fix anything here. This skill only reports.
