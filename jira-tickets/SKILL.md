---
name: jira-tickets
description: Split a PRD or spec into a Jira epic and per-repo tickets, each with acceptance criteria, estimate, dependencies and blast radius, then create them through the Atlassian MCP or write markdown plus a CSV for Jira import. Use after prd-writer, or when someone says "break this into tickets", "create the Jira tickets", "plan the sprint work for this", or "how many points is this".
---

# Jira Tickets

PRD in, tickets out. Each ticket must be buildable by a dev who reads only that ticket.

## Step 1: Gather inputs

- The PRD (usually `docs/prd/*.md`). If there isn't one and the request is fuzzy, run `prd-writer` first.
- The repo map (`repo-map.md` in the parent folder, or `docs/repo-map.md`) for which repo owns what.
- An `impact-analysis` report if there is one. If the feature touches shared tables, APIs or events and there's no report, run it first or flag the risk on the tickets.
- Ask once: the Jira project key, the issue types the project uses (Epic/Story/Task/Bug), and story points or hours. Default to points (1, 2, 3, 5, 8).

## Step 2: Slice

- One epic per feature; tickets live under it.
- One repo per ticket. A change across `api` and `web` is at least two tickets with a dependency between them.
- Slice vertically: each ticket delivers something testable (endpoint + tests, screen + tests), not "models", then "handlers", then "tests".
- Anything with its own deploy risk gets its own ticket: migrations on big tables, backfills, breaking changes to shared APIs or events, the cleanup phase of a `safe-change`.
- Anything over 8 points gets split. An unknown too big to estimate becomes a time-boxed `spike` ticket.

## Step 3: Write each ticket

```
Summary: [api] Add void endpoint for invoices
Epic: <epic>    Repo: api    Labels: billing, api    Estimate: 3

Context
One or two lines on why, with a link to the PRD section.

What to build
- POST /invoices/{id}/void (org admins only)
- invoices.status gets `void`; add voided_at, voided_by

Acceptance criteria
1. ... (copied or narrowed from the PRD, testable)

Blast radius
- invoices is read by the reporting repo's nightly export (jobs/export.py); it must handle `void`. See ABC-125.
- Migration adds 2 nullable columns to invoices (~2M rows): metadata-only on Postgres, safe.

Dependencies
- Blocks: ABC-124 (web: Void button)
- Blocked by: none

Suggested route
impact-analysis → feature-build → test-writer → pr-description
```

UI tickets route to `jira-build`. Attach or link the mockup for every screen and state the ticket covers (Figma frame links preferred) and paste the exact UI copy; `jira-build` treats those images as the spec.

Estimate guide, unless the team has its own: 1 = trivial, known pattern; 2 = a few hours; 3 = about a day in one module; 5 = several files or an unfamiliar area; 8 = multi-day or risky. Bump one size for untested legacy code.

## Step 4: Review with the dev, then create

Show the whole list as a table first (placeholder key, summary, repo, estimate, blocks / blocked by) and let the dev edit it. Then, in this order of preference:

1. **Atlassian MCP connected:** confirm the project key, create the epic, then the tickets under it, then the issue links. Report the created keys.
2. **REST**, if `JIRA_URL`, `JIRA_EMAIL` and `JIRA_API_TOKEN` are set: `curl -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -X POST "$JIRA_URL/rest/api/2/issue"` per ticket (v2 accepts a plain-text description; v3 needs Atlassian Document Format), then `POST /rest/api/2/issueLink` for each dependency. Never echo the token.
3. **No Jira access:** write `docs/prd/<slug>-tickets.md` with every ticket in full, plus `docs/prd/<slug>-tickets.csv` for Jira's CSV import with columns `Summary,Issue Type,Description,Labels,Story Points,Epic Link` (newer Jira Cloud projects map the epic to `Parent`). Quote any field that contains commas or newlines. Mention that connecting the Atlassian MCP automates this next time.

Never create tickets before the dev confirms the list.

## Rules

- Every ticket has a repo and acceptance criteria. No exceptions.
- Dependencies point both ways (blocks / blocked by) and match across tickets.
- Blast radius is specific: name the consumer, the table and its size, the endpoint. "Might affect other things" isn't blast radius.
- Keep the PRD's names for things. If a ticket renames something, say so in the ticket.
