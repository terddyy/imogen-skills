---
name: prd-writer
description: Turn a rough feature request into a PRD with testable acceptance criteria, edge cases, and the repos and modules it touches. Use when a client or PM asks for a new feature, when a request is vague ("can we add a way to..."), when someone says "write a spec for this" or "write the PRD", or before creating Jira tickets. First step of the "client wants a new feature" route.
---

# PRD Writer

Rough request in, buildable spec out. `jira-tickets` and `impact-analysis` read the PRD next, so a dev who wasn't on the client call has to be able to build from it.

## Step 1: Read what's there

- The request as given: Slack thread, email, call notes, Jira ticket, screenshots.
- The repo map (`repo-map.md` in the parent folder, or `docs/repo-map.md`) for which repos and modules own the area. Check it against the code; it can be stale.
- The code in that area: the tables, endpoints, screens and jobs the request mentions. Don't spec something that already exists, and note what can be reused.
- Earlier specs in `docs/prd/` (or wherever the team keeps them), to match their format.

## Step 2: Ask the gaps, in one batch

Only ask what the code and the request can't answer. One message, at most ~6 questions, each with your best guess so the dev can just confirm:

```
1. Who can do this: any signed-in user, or only org admins? (guess: admins, same as invoice editing in billing/permissions.ts)
2. What happens to invoices already sent? (guess: they can be voided too, the customer isn't re-notified)
```

Usual gaps: who (roles, permissions, tenants), existing data, limits (sizes, counts, rates), notifications, what "done" looks like to the client, and what to cut if the deadline is fixed.

If nobody knows, put it under Open questions and keep going. If the request is mostly unknowns, run `grill-plan` first.

## Step 3: Write the PRD

Save to `docs/prd/YYYY-MM-DD-<slug>.md` in the repo that owns most of the feature (or the team's spec folder). Cut sections that really don't apply:

```markdown
# <Feature name>

Status: Draft | Requested by: <client/PM> | Date: YYYY-MM-DD

## Problem
What's wrong or missing today, and for whom. 2-4 sentences.

## Goal
What success looks like, measurable where possible.

## Out of scope
Things someone might reasonably assume are included but aren't.

## User stories
- As a <role>, I want <action> so that <outcome>.

## Acceptance criteria
Numbered and testable. Given/When/Then where it helps.
1. Given an org admin, when they void a draft invoice, then its status becomes `void` and the API returns 200.
2. Given a non-admin, when they try the same, then they get 403 and nothing changes.

## Edge cases
Empty and max sizes, duplicates, concurrent edits, timezones, soft-deleted rows,
permissions on related records, existing data, retries and partial failures.

## Affected repos and modules
| Repo | Module / area | Change |
| --- | --- | --- |
| api | billing | new endpoint, new column on invoices |
| web | invoices page | Void button + confirm modal |

## Data and API changes
New or changed tables/fields and migrations; new or changed endpoints, events and
response fields. Flag anything another repo, app or client consumes.

## UI
Screens and states, with mockup links (Figma frames preferred) and the exact copy.

## Rollout
Feature flag? Backfill? Deploy order across repos?

## Open questions
- <question> (owner: <who>)
```

## Step 4: Hand off

Give the dev the file path and the 3-5 things most likely to cause rework: unclear acceptance criteria, open questions, cross-repo or contract changes. Next: `jira-tickets` to split it, `impact-analysis` first if the affected-repos table is a guess, or `adr` if the PRD forces an architecture decision.

## Rules

- Acceptance criteria are testable. "Should be fast" isn't; "the list endpoint returns in under 300ms for 1k rows" is.
- Use the code's names for things (tables, modules, components), not the client's wording. Note the mapping when they differ.
- Don't design the implementation beyond what's needed to fill in affected repos and data/API changes.
- Don't invent requirements to fill a section. An open question beats a guess written as a fact.
