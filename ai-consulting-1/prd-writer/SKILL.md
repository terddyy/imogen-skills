---
name: prd-writer
description: Turn a rough client request into a PRD with acceptance criteria, edge cases and affected repos. Use when a client or PM asks for a new feature, when a request is vague, or before creating Jira tickets. First step of the "client wants a new feature" route.
---

# PRD Writer

Rough request in, buildable spec out. The PRD is what `jira-tickets` and `impact-analysis` read next, so it has to be specific enough that a dev who wasn't in the client call could build from it.

## Step 1: Read what's there

- The request as given (Slack message, email, call notes, Jira ticket).
- The repo map (`../repo-map.md` or `docs/repo-map.md`) to see which repos and Django apps own the area.
- The code in that area: models, endpoints and screens the request mentions. Don't spec something that already exists.

## Step 2: Ask the gaps, in one batch

List only the questions you can't answer from the code or the request. Batch them in one message, max ~6, each with your best guess so the dev can just confirm:

```
1. Who can do this: any logged-in user, or only org admins? (guess: org admins, matches the existing invoice permissions)
2. ...
```

Typical gaps: who (roles/permissions), what happens to existing data, limits (sizes, counts, rate), notifications, what "done" looks like to the client, deadline-driven scope cuts.

If the dev doesn't know, record it under Open questions and move on. Don't block.

## Step 3: Write the PRD

Save to `docs/prd/YYYY-MM-DD-<slug>.md` in the main repo for the feature (create the folder if needed). Use this template, and cut sections that genuinely don't apply:

```markdown
# <Feature name>

Status: Draft | Requested by: <client/PM> | Date: <YYYY-MM-DD>

## Problem
What's wrong or missing today, and for whom. 2-4 sentences.

## Goal
What success looks like, measurable where possible.

## Out of scope
Things someone might reasonably assume are included but aren't.

## User stories
- As a <role>, I want <action> so that <outcome>.

## Acceptance criteria
Numbered, testable, Given/When/Then where it helps.
1. Given an org admin, when they POST /api/invoices/{id}/void/, then the invoice status becomes `void` and a 200 is returned.
2. Given a non-admin, when they call the same endpoint, then they get 403 and nothing changes.

## Edge cases
- Empty / max sizes, duplicates, concurrent edits, timezones, soft-deleted records, permissions on related objects, what happens to existing rows.

## Affected repos and apps
| Repo | App / area | Change |
| --- | --- | --- |
| backend | billing | new endpoint, new field on Invoice |
| web-app | invoices page | new button + confirm modal |

## Data and API changes
New/changed models and fields, migrations needed, new/changed endpoints and response fields. Flag anything another repo consumes.

## Rollout
Feature flag? Backfill? Order of deploys if multiple repos.

## Open questions
- <question> (owner: <who>)
```

## Step 4: Hand off

Show the dev the file path and the 3-5 things most likely to cause rework (unclear AC, open questions, cross-repo changes). Then suggest the next step: `jira-tickets` to split it, or `impact-analysis` first if the "Affected repos" table looks uncertain.

## Rules

- Acceptance criteria must be testable. "Should be fast" isn't; "list endpoint returns under 300ms for 1k rows" is.
- Use the project's own names for things (model names, app names), not the client's wording, and note the mapping if they differ.
- Don't design the implementation here beyond what's needed to list affected repos and API/data changes.
