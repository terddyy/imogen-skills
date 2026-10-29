---
name: jira-tickets
description: Split a PRD or spec into Jira epics and tickets per repo, each with acceptance criteria, estimate, dependencies and blast radius. Use after prd-writer, when someone says "break this into tickets", "create the Jira tickets", or "plan the sprint work for this feature".
---

# Jira Tickets

PRD in, tickets out. Each ticket should be pick-up-able by a dev who only reads that ticket.

## Step 1: Gather inputs

- The PRD (usually `docs/prd/*.md`). If there isn't one and the request is fuzzy, suggest `prd-writer` first.
- The repo map, for which repo owns what.
- An `impact-analysis` report if one exists. If the feature touches shared models or APIs and there's no report, run `impact-analysis` first or note the risk on the tickets.
- Ask once: Jira project key, and whether the team uses story points or hours. Default to story points (1, 2, 3, 5, 8).

## Step 2: Slice

- One epic per feature. Tickets live under it.
- Tickets are per repo. A change that spans backend and frontend is at least two tickets with a dependency between them.
- Slice vertically where possible: a ticket delivers something testable (endpoint + tests), not "write models" then "write views" then "write tests".
- Separate tickets for anything with its own deploy risk: migrations on big tables, backfills, contract changes to shared APIs.
- Anything over 8 points gets split.

## Step 3: Write each ticket

```
Summary: [backend] Add void endpoint for invoices
Epic: <epic>
Repo: backend   Labels: billing, api
Estimate: 3

Context
One or two lines on why, linking the PRD section.

What to build
- POST /api/invoices/{id}/void/ (org admins only)
- Invoice.status gets `void`; voided_at, voided_by fields

Acceptance criteria
1. ... (copied or narrowed from the PRD, testable)

Blast radius
- Invoice model is read by reporting-service (nightly export). New status value must be handled there. See ABC-125.
- Migration adds 2 nullable columns to billing_invoice (~2M rows): metadata-only on Postgres, safe.

Dependencies
- Blocks: ABC-124 (web-app void button)
- Blocked by: none

Suggested route
impact-analysis → django-feature → test-writer → pr-description
```

Estimate guide (adjust if the team has its own): 1 = trivial, known pattern; 3 = a day-ish, one app; 5 = several files or unfamiliar area; 8 = multi-day or risky. Bump one size for untested legacy code.

## Step 4: Review with the dev, then create

Show the full list as a table first (key placeholder, summary, repo, estimate, blocks/blocked-by) and let the dev edit. Then:

- **Jira MCP connected** (Atlassian tools available): confirm the project key, then create the epic, the tickets, and the issue links. Report the created keys.
- **No Jira access**: write `docs/prd/<slug>-tickets.md` with all tickets, plus a `<slug>-tickets.csv` with columns `Summary,Issue Type,Description,Labels,Story Points,Epic Link` for Jira's CSV import. Tell the dev to set up the Atlassian MCP if they want this automated next time.

Never create tickets without the dev confirming the list.

## Rules

- Every ticket has acceptance criteria and a repo. No exceptions.
- Dependencies point both ways (blocks / blocked by) and match across tickets.
- Blast radius is specific: name the consumer, the table size, the endpoint. "Might affect other things" isn't blast radius.
