---
name: grill-plan
description: Stress-test a plan, design or approach by interviewing the dev one question at a time, walking every branch of the decision tree until each one is settled, with a recommended answer on every question. Checks the code instead of asking when the code can answer. Use when "grill me on this", "poke holes in my plan", "is this design OK", "what am I missing", before starting a big feature, or when a PRD or ticket feels vague.
---

# Grill Plan

Find the gaps in a plan before code gets written. One question at a time, each with a recommended answer, until every branch is decided or explicitly parked.

## Step 0: Read the plan and the code it touches

1. Get the plan: a pasted doc, a PRD, a ticket (Jira via Atlassian MCP, else REST with JIRA_URL / JIRA_EMAIL / JIRA_API_TOKEN, else ask the dev to paste), or a chat description.
2. Read `repo-map.md` (parent folder of the repo) or `docs/repo-map.md` if present, then check the parts the plan touches in the actual code. The map can be stale.
3. Read existing decisions: `docs/adr/`, `docs/decisions/`, `CONTEXT.md`, `docs/glossary.md`. Do not re-ask what is already decided there; quote it instead.

## Step 1: Build the decision tree

List the open decisions privately before asking anything. Typical branches:

- Scope: what is in, what is explicitly out, what is v1 vs later.
- Data: new tables/fields, ownership, migration of existing rows, deletes.
- Interfaces: API shape, who calls it, backward compatibility.
- Failure: what happens on timeout, partial failure, retry, duplicate submit.
- Permissions: who can see and do what, multi-tenant boundaries.
- Rollout: feature flag, migration order, rollback path.
- Testing: how anyone will know it works.

Order them so the answers that change other answers come first (scope before data, data before API).

## Step 2: Ask, one question per message

Each question uses this shape:

```
Q4 (data): When an invoice is cancelled, do its line items stay or go?
Why it matters: reports in billing/reports.py:88 sum line items without checking status.
Recommended: keep them, add `cancelled_at` on the invoice, filter in reports.
Options: (a) recommended  (b) hard delete  (c) something else
```

- Before asking, check if the code answers it. "Does the user model already have a timezone?" is a grep, not a question. Say what you found: "Checked: `User.timezone` exists (accounts/models.py:41), so I'll use it."
- Ask one question. Wait for the answer. Follow the branch it opens before moving on.
- If the answer conflicts with an earlier answer or with the code, say so right away.
- If the dev says "don't know", offer the recommended default and mark it as an assumption.
- Stop drilling a branch when the answer would not change what gets built.

## Step 3: Summarize

When every branch is decided or parked, print:

```
Decisions
1. Cancelled invoices keep line items; reports filter on cancelled_at.
2. ...
Assumptions (dev unsure, default taken)
- Retry 3x with backoff on the payment webhook.
Parked (needs someone else)
- Refund policy for partial cancels: ask product (Maria).
Worth an ADR
- #1 (changes how reporting reads invoices), #3 (new queue dependency)
```

## Rules

- One question per message. No question lists.
- Every question carries a recommendation and the reason, tied to a file or a fact where possible.
- Never ask what the code, the docs or an existing ADR already answers.
- Do not start implementing during the grilling.
- Keep the dev's words for domain terms; flag synonyms ("account" vs "customer") and settle on one.

Next: `adr` for the decisions marked worth recording, then `prd-writer` or `jira-tickets` to turn the plan into work, or `spike` if a question can only be answered by trying it.
