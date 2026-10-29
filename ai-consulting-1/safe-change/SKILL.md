---
name: safe-change
description: Change a model field, endpoint, serializer field, function signature or URL without breaking existing callers, using expand-and-contract steps that each ship separately. Use when renaming or removing something other code depends on, changing a response shape, "I need to change this model/endpoint", or "I'm scared to touch this".
---

# Safe Change

Never change something in place when other code depends on it. Add the new thing next to the old, move callers over, then remove the old. Each phase is its own PR and deploy, and each one is safe to roll back on its own.

## Step 0: Know the callers

You need the full list of callers before you start: run `impact-analysis` if you haven't. If the code being changed has thin test coverage, run `characterization-tests` first so you'll notice if behavior shifts.

## Step 1: Pick the pattern

**Rename a model field** (`status` → `state`)
1. Expand: add `state` (nullable or with default). Write to both on save. Migration + backfill (`django-migrations`).
2. Migrate readers: switch all reads (code, serializers, filters, admin, raw SQL, other repos) to `state`.
3. Stop writing `status`. Make it nullable if it wasn't.
4. Contract: remove the field from the model with `SeparateDatabaseAndState` (state only), deploy, then drop the column in a later migration.

**Rename / remove an API response field** (consumed by another repo)
1. Expand: return both `status` and `state`. Add `state` to the contract test.
2. Consumers switch to `state` (their PRs, their deploys; see `cross-repo-change`).
3. Confirm no one reads `status`: search consumer repos, check API logs if you have them.
4. Contract: remove `status`, update the contract test. Mention it in release notes.

**Change a request payload / validation**
1. Accept both old and new input shapes. Normalize to the new one in the serializer.
2. Log (or count) requests that still use the old shape.
3. When the count is zero for a full release cycle, drop the old shape.

**Change a function or service signature**
1. Add the new parameter with a default, or add a new function and make the old one a thin wrapper that calls it.
2. Move callers. `grep` for every call site, including Celery task calls (`.delay(` / `.apply_async(`): queued tasks serialized with the old args may still be in the broker during deploy, so the task must accept both for one release.
3. Delete the wrapper/old param.

**Change a URL**
1. Add the new route; keep the old route pointing at the same view.
2. Move internal links and consumers.
3. Old route returns a redirect (for browser URLs) or stays until consumers are done (for APIs), then goes.

**Change behavior behind the same interface**
Use a feature flag (whatever the project uses: django-waffle, settings flag, DB flag). Default off, turn on per environment, remove the flag and the old branch afterwards.

## Step 2: Write the plan down

Before coding, write the phases as a checklist in the ticket or PR description:

```
Phase 1 (this PR): add `state`, dual-write, backfill        deploy: backend
Phase 2: switch reads in backend + web-app                     deploy: backend, then web-app
Phase 3: stop writing `status`, drop from model state          deploy: backend
Phase 4: drop column                                           deploy: backend (next release)
Rollback for each phase: revert the PR; no data loss because old field is still written until phase 3.
```

Get the dev to confirm, then implement only the current phase.

## Step 3: Implement the current phase

- Tests for both old and new paths while both exist.
- Each phase must leave main deployable and every consumer working.
- Mark the temporary code clearly: `# expand/contract: remove after ABC-123 phase 3`.
- Create the follow-up tickets for the remaining phases (`jira-tickets`), so the contract step doesn't get forgotten.

## Rules

- One phase per PR. A PR that adds the new field *and* removes the old one isn't a safe change.
- Never remove anything that another repo reads until that repo has deployed without it.
- Never rename a model field or DB column in a single migration on a live table.
