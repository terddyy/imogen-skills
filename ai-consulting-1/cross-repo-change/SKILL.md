---
name: cross-repo-change
description: Plan and run a change that spans multiple repos — orders the PRs and deploys so nothing breaks in between, links the PRs and tickets, and produces a deploy checklist. Use when a feature or fix "touches the other repo", when a backend API change needs a frontend or service change, or when changing anything another repo consumes.
---

# Cross-Repo Change

The rule: at every moment between the first deploy and the last, every deployed version of every repo must work with every other. You get there by ordering the changes, not by deploying "at the same time" (which never actually happens).

## Step 1: Inputs

- The `impact-analysis` report (run it first if it doesn't exist). You need the list of consumers per repo.
- The repo map's Connections table: how the repos talk (HTTP, shared DB, queue, webhook, shared package).
- How each repo deploys and how long it takes; mobile apps are the slow case since old versions stay in the wild.

## Step 2: Order the changes

Default order for a provider/consumer change (backend API used by web-app, say):

1. **Provider expands.** Backend adds the new field/endpoint/behavior without removing anything. Contract tests updated to cover the new shape (`contract-tests`). Deploy.
2. **Consumers switch.** Each consumer moves to the new shape. Deploy each.
3. **Provider contracts.** Backend removes the old shape once every consumer has deployed (and, for mobile, once old app versions are below your support threshold). Deploy.

Other cases:

- **Consumer needs a new capability, nothing removed**: provider first, consumer second. Two steps.
- **Shared database** (another service reads your tables): treat columns like API fields. Add, let readers switch, then drop. Never rename or drop a column a reader still uses.
- **Queue / webhook payloads**: consumers must accept both old and new payloads before producers send the new one. Consumer first here.
- **Shared Python package**: release a new version, bump it in each repo separately; don't break the old version's API in the same release.
- **Can't order it safely** (truly simultaneous change needed): use a feature flag in the consumer, deploy everything with the flag off, then flip it.

## Step 3: Write the plan

Put this in the epic or the first PR, and link it from every PR:

```markdown
## Cross-repo plan: <change>

| # | Repo | PR | Change | Deploy after | Safe to roll back? |
| - | ---- | -- | ------ | ------------ | ------------------ |
| 1 | backend | #412 | add `state` to /api/invoices, keep `status` | - | yes |
| 2 | web-app | #88 | read `state` | #412 live in prod | yes |
| 3 | reporting | #31 | read `state` column | #412 live in prod | yes |
| 4 | backend | #420 | remove `status` | #88 and #31 live in prod | yes (re-add field) |

Contract tests: backend/tests/contracts/test_invoice_contract.py
Feature flag: none
```

## Step 4: Execute one repo at a time

- Branch names share the ticket key across repos (`ABC-123-invoice-state`) so they're easy to find.
- Each PR description links the plan and states "depends on: <repo>#<n> deployed to <env>".
- Before merging a step, check that its "Deploy after" condition is actually met in the target environment, not just merged.
- Create Jira tickets for the later steps (especially the contract step) so it isn't forgotten.

## Rules

- Never merge a PR that only works if another repo's unmerged PR is deployed.
- Never remove something a consumer uses in the same release that adds its replacement.
- If the plan has more than ~4 steps, check whether the change can be made smaller.
