---
name: adr
description: Record architecture decisions as numbered ADRs (context, decision, consequences, status) and keep a short glossary of the project's domain terms. Detects and follows any existing ADR folder and format first. Use when "write this decision down", "add an ADR", "why did we pick X", "we decided to switch to Y", after a grill-plan or spike, or when people keep using different words for the same thing.
---

# ADR

Write down why the code is the way it is, in a place the next dev will find it. One decision per file, plus a glossary so everyone uses the same words.

## Step 0: Find the existing convention

1. Look for an ADR folder: `docs/adr/`, `doc/adr/`, `docs/decisions/`, `adr/`, `architecture/decisions/`. Also check for `.adr-dir` (adr-tools) or `log4brains.yml`.
2. If one exists, open the two most recent ADRs and copy their numbering, file naming, headings, status values and date format exactly. Do not "upgrade" their template.
3. Look for a glossary: `CONTEXT.md`, `docs/glossary.md`, `GLOSSARY.md`, or a terms section in the README.
4. If nothing exists, use `docs/adr/` and `docs/glossary.md` (or `CONTEXT.md` if the repo already keeps agent context at the root). Tell the dev where you put them.

## Step 1: Collect the decision

Get these from the dev, the grill-plan summary, the spike note, or the PR thread:

- What was decided, in one sentence.
- The forces: constraints, deadlines, numbers, what broke before.
- Options that were considered and why each lost.
- What gets easier, what gets harder, what is now locked in.

If any of these is missing, ask for it. A decision with no rejected options is usually a description, not a decision.

## Step 2: Write the ADR

Next number = highest existing + 1, zero-padded to match (`0007`). File: `docs/adr/0007-use-postgres-row-level-security.md`.

```
# 7. Use Postgres row-level security for tenant isolation

Date: 2026-11-03
Status: Accepted

## Context
Tenant filtering is done by hand in 40+ queries; two leaks in 2026 (INC-212, INC-230)...

## Decision
Enable RLS on all tenant tables; app sets `app.tenant_id` per connection.

## Options considered
- Manual `WHERE tenant_id` (status quo): already failed twice.
- Schema per tenant: migrations x N tenants, rejected.

## Consequences
- Easier: new queries are safe by default.
- Harder: background jobs must set the tenant explicitly; superuser bypasses RLS.
- Follow-ups: ABC-311 migrate reporting jobs.
```

Keep it under a page. Link tickets, PRs and spike notes instead of pasting them.

## Step 3: Supersede, don't edit

When a decision changes, write a new ADR and set the old one's status to `Superseded by 0012`. Only fix typos or links in an accepted ADR.

## Step 4: Update the glossary

Add or fix terms that came up. One line each, alphabetical, with the code name if it differs:

```
**Workspace**: a paying customer's area. Code: `Organization` (orgs/models.py). Not "account".
```

Flag terms used two ways in the code and ask which one wins.

## Rules

- Follow the repo's existing ADR format over this template.
- One decision per ADR. Never renumber or delete old ADRs.
- Statuses: Proposed, Accepted, Superseded, Deprecated (or whatever the repo already uses).
- Write for a dev joining in a year: no "as discussed", no names without roles.

Next: `pr-description` to link the ADR from the PR, or `docs-writer` if the README needs to reflect the decision.
