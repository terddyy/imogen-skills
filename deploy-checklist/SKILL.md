---
name: deploy-checklist
description: Build a pre-deploy and post-deploy checklist for a specific release - migration order, env vars and secrets present in the target environment, feature flags, backward compatibility with the version currently running, rollback plan, smoke tests, and which dashboards and alerts to watch. Use when "we're deploying today", "is this safe to ship", "release checklist", "what could go wrong with this deploy", "how do we roll back", or before any release that touches the database, config or a shared API.
---

# Deploy Checklist

A checklist for this release, built from what's actually in it. Not a generic template: every line traces to a change in the diff.

## Step 0: Read the stack

Find how the repo deploys: CI deploy jobs (`.github/workflows/deploy*.yml`, `.gitlab-ci.yml`), platform config (`vercel.json`, `fly.toml`, `render.yaml`, `Procfile`, Helm charts, Terraform, `serverless.yml`), the migration tool, the feature-flag system (LaunchDarkly, Unleash, GrowthBook, env flags, a DB table), and where logs and metrics live. Check for an existing release doc or runbook and follow it.

## Step 1: What's in the release

`git log <deployed-sha>..<release-sha> --oneline` and `git diff --stat` between the two. Get the deployed SHA from the platform, a tag, or ask. Sort the changes into:
- schema migrations and data backfills
- new or changed env vars, secrets, config
- API or event contract changes other services consume
- new background jobs, cron schedules, queues
- dependency or runtime version bumps
- feature-flagged code

## Step 2: Pre-deploy checks

1. **Migrations**: list them in order. Each must work with the old code still running (old pods serve traffic during rollout). Additive first (new nullable column, new table, index created concurrently); destructive changes (drop, rename, NOT NULL on a live column) belong in a later release (`safe-change`, `db-migrations`). Note long locks and big-table backfills; time them on a staging copy.
2. **Order of operations**: migrate before or after deploy? Which service ships first when several change (`cross-repo-change`)? Write it as numbered steps.
3. **Env vars and secrets**: every new var exists in the target environment. Check names only, never print values (platform CLI env list, the secret manager's list command, or ask the dev to confirm).
4. **Feature flags**: new code paths default off in production. Know who flips them and when.
5. **Backward compatibility**: the old client/consumer still works against the new server, and the new code still works against old data and queued jobs serialized by the old version. Contract tests pass (`contract-tests`).
6. **CI green** on the exact SHA being deployed, staging deployed and smoke-tested.
7. **Rollback plan**: how to roll back the app (redeploy previous SHA, platform rollback, revert PR), and whether that's safe after the migrations ran. If a migration can't be reversed safely, say so and say what happens instead (roll forward with a fix).

## Step 3: Deploy and post-deploy

1. Deploy in the order from Step 2. Note the time.
2. **Smoke tests**: the 3-5 critical paths this release touches, plus login and the main flow. Run the repo's smoke/e2e suite against prod if it has one; otherwise list the manual clicks.
3. **Watch** for 15-30 minutes: error rate, p95 latency, the specific endpoints changed, job queue depth, DB CPU/locks. Name the dashboards and alerts.
4. **Rollback triggers**, decided before deploying: e.g. error rate above 2x baseline for 5 minutes, any 5xx on checkout, migration running past 10 minutes.

## Step 4: Output

```
Release: v1.42 (a1b2c3d -> e4f5a6b), backend + web
Pre-deploy
[ ] Migration 0087 add_invoice_state (nullable, additive) - safe with old code
[ ] Migration 0088 index on invoices(org_id, state) CONCURRENTLY - ~3 min on staging copy
[ ] PAYMENTS_WEBHOOK_SECRET set in prod (checked by name)
[ ] Flag new-invoice-flow default off in prod
Order: 1) migrate 2) deploy backend 3) deploy web
Rollback: redeploy a1b2c3d; migrations are additive, leave them
Post-deploy
[ ] Smoke: login, create invoice, pay invoice, webhook received
[ ] Watch 30 min: API error rate, /invoices p95, payments queue depth
Rollback if: 5xx on /payments > 1% for 5 min
```

Post it in the PR or release ticket. After the deploy, tick the boxes and note anything that surprised you.

## Rules

- Every item traces to something in this release. Delete generic items that don't apply.
- Never print secret values; check presence by name.
- If there's no rollback path, say it plainly and get an explicit go from the dev before deploying.
- Don't run deploys or production migrations yourself unless the dev explicitly asks.

Next: `regression-postmortem` if it goes wrong, `pr-description` to attach the checklist.
