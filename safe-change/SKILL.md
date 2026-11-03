---
name: safe-change
description: Change a DB column, endpoint, response field, function signature, event payload or URL without breaking existing callers, using expand-and-contract phases that each ship and roll back on their own. Works on any stack. Use when renaming or removing something other code depends on, changing a response shape, "I need to change this model/endpoint", "will this break anything", or "I'm scared to touch this".
---

# Safe Change

Never change something in place when other code depends on it. Add the new thing next to the old, move callers over, then remove the old. Each phase is its own PR and deploy, and each is safe to roll back by itself.

## Step 0: Know the callers

You need the full caller list before you start: run `impact-analysis` if you haven't. Include other repos, background jobs, scheduled tasks, mobile apps, reports and raw SQL. If the code being changed has thin test coverage, run `characterization-tests` first so a behavior shift shows up as a failing test.

## Step 1: Pick the pattern

**Rename a DB column** (`status` to `state`)
1. Expand: add `state` (nullable or with a default). Write to both on every write. Backfill in batches (`db-migrations`).
2. Move readers: code, queries, filters, admin screens, reports, other repos.
3. Stop writing `status`. Make it nullable if it wasn't.
4. Contract: remove it from the model/ORM mapping first, deploy, then drop the column in a later migration.

**Rename or remove an API response field** (consumed by another repo or client)
1. Expand: return both `status` and `state`. Add `state` to the contract test (`contract-tests`).
2. Consumers switch to `state`: their PRs, their deploys (`cross-repo-change`).
3. Confirm nothing reads `status`: search consumer repos, check API logs if you have them. Mobile clients stay in the wild; check version adoption.
4. Contract: remove `status`, update the contract test, note it in release notes.

**Change a request payload or validation**
1. Accept both old and new shapes. Normalize to the new one at the boundary.
2. Log or count requests still using the old shape.
3. When the count stays at zero for a full release cycle, drop the old shape.

**Change a function or method signature**
1. Add the new parameter with a default, or add a new function and turn the old one into a thin wrapper.
2. Move callers. Search every call site, including job/queue enqueues (`.delay(`, `queue.add(`, `perform_later`): jobs serialized with old args can sit in the queue during deploy, so the worker must accept both for one release.
3. Delete the wrapper or old parameter.

**Change an event or message payload**
Consumers accept both shapes and deploy first. Then producers send the new shape. Then consumers drop the old one.

**Change a URL or route**
1. Add the new route; keep the old one pointing at the same handler.
2. Move internal links and consumers.
3. Old route becomes a redirect (browser URLs) or stays until consumers are done (APIs), then goes.

**Change behavior behind the same interface**
Use whatever feature flag system the repo has (LaunchDarkly, Unleash, env/config flag, DB flag). Default off, enable per environment, then delete the flag and the old branch.

## Step 2: Write the plan down

Before coding, put the phases in the ticket or PR description:

```
Phase 1 (this PR): add `state`, dual-write, backfill      deploy: api
Phase 2: switch reads in api + web                        deploy: api, then web
Phase 3: stop writing `status`, drop from ORM mapping     deploy: api
Phase 4: drop column                                      deploy: api (next release)
Rollback: revert the phase's PR. No data loss; `status` is written until phase 3.
```

Get the dev to confirm, then implement only the current phase.

## Step 3: Implement the current phase

- Tests cover both the old and new paths while both exist.
- Each phase leaves main deployable and every consumer working.
- Mark temporary code so it's easy to find later: `// expand/contract: remove in ABC-123 phase 3`.
- Create follow-up tickets for the remaining phases (`jira-tickets`) so the contract step doesn't get forgotten.

## Rules

- One phase per PR. A PR that adds the new thing and removes the old one is not a safe change.
- Never remove anything another repo or client reads until it has deployed without it.
- Never rename a column or table in a single migration on a live database.
- Running code must work with both the old and the new schema during a deploy.

Next: `db-migrations` for the schema steps, `cross-repo-change` when phases span repos, `deploy-checklist` before each deploy.
