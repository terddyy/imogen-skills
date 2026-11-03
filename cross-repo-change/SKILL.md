---
name: cross-repo-change
description: Plan and run a change that spans more than one repo or deployable. Orders the PRs and deploys so nothing breaks in between, links the PRs and tickets, and produces a step-by-step deploy plan. Use when a feature or fix "touches the other repo", when a backend API change needs a frontend, mobile or service change, when changing a shared package, event payload or shared table, or when changing anything another repo consumes.
---

# Cross-Repo Change

At every moment between the first deploy and the last, every deployed version of every repo must work with every other. You get there by ordering the changes, not by deploying "at the same time", which never actually happens.

## Step 1: Inputs

- The `impact-analysis` report (run it first if it doesn't exist). You need the consumers per repo.
- The repo map's connections section (`../repo-map.md` or `docs/repo-map.md`): how the repos talk (HTTP, GraphQL, gRPC, shared DB, queue, webhook, shared package). Verify it against code.
- How each repo deploys and how long it takes: CI/CD config, release cadence. Mobile apps are the slow case, since old versions stay installed for months.

## Step 2: Order the changes

Default order for a provider/consumer change (an API used by a web app, say):

1. **Provider expands.** Add the new field, endpoint or behavior without removing anything. Update contract tests to cover the new shape (`contract-tests`). Deploy.
2. **Consumers switch.** Each consumer moves to the new shape. Deploy each.
3. **Provider contracts.** Remove the old shape once every consumer has deployed (and, for mobile, once old app versions are below the support threshold). Deploy.

Other cases:

- **Consumer needs a new capability, nothing removed**: provider first, consumer second.
- **Shared database** (another service reads your tables): treat columns like API fields. Add, let readers switch, then drop (`db-migrations`). Never rename or drop a column a reader still uses.
- **Queue, event or webhook payloads**: consumers must accept both old and new payloads before producers send the new one. Consumer first here.
- **Shared package or SDK** (npm, PyPI, Go module, internal registry): release a new version, bump it in each repo separately. Don't break the old version's API in the same release; deprecate first.
- **Generated clients** (OpenAPI, GraphQL codegen, protobuf): publish the contract change, regenerate in each consumer in its own PR.
- **Can't be ordered safely**: put the consumer behind a feature flag, deploy everything with it off, then turn it on.

## Step 3: Write the plan

Put this in the epic or the first PR, and link it from every PR:

```markdown
## Cross-repo plan: <change>

| # | Repo | PR | Change | Deploy after | Safe to roll back? |
| - | ---- | -- | ------ | ------------ | ------------------ |
| 1 | api | #412 | add `state` to GET /invoices, keep `status` | - | yes |
| 2 | web | #88 | read `state` | #412 live in prod | yes |
| 3 | reporting | #31 | read `state` column | #412 live in prod | yes |
| 4 | api | #420 | remove `status` | #88 and #31 live in prod | yes (re-add field) |

Contract tests: api/tests/contracts/invoice.contract.test.ts
Feature flag: none
```

## Step 4: Execute one repo at a time

- Branch names share the ticket key across repos (`ABC-123-invoice-state`) so they're easy to find.
- Each PR description links the plan and states "depends on: <repo>#<n> deployed to <env>" (`pr-description`).
- Before merging a step, check that its "Deploy after" condition is actually met in the target environment, not just merged.
- Create tickets for the later steps, especially the contract step, so it isn't forgotten (`jira-tickets` or `imogen-issue`).
- Run `deploy-checklist` for each deploy in the plan.

## Rules

- Never merge a PR that only works if another repo's unmerged or undeployed PR is live.
- Never remove something a consumer uses in the same release that adds its replacement.
- Each step must be safe to roll back without rolling back another repo.
- If the plan has more than about four steps, check whether the change can be made smaller.

For the expand/contract details inside each repo, use `safe-change`.
