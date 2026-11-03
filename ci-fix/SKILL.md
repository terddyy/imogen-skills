---
name: ci-fix
description: Diagnose and fix a failing CI pipeline (GitHub Actions, GitLab CI, CircleCI, Bitbucket, Azure Pipelines) - pull the failed logs, classify the failure (real test failure, flaky test, missing env/secret, cache problem, tool or dependency version drift, infra), reproduce it locally, and fix the root cause without disabling the check. Use when "CI is red", "the build is failing", "tests pass locally but fail in CI", "the pipeline broke after merge", or "my PR checks are failing".
---

# CI Fix

Get the pipeline green by fixing why it's red. Skipping, muting or deleting the check is not a fix.

## Step 0: Read the stack

Find the CI config: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `.circleci/config.yml`, `bitbucket-pipelines.yml`, `azure-pipelines.yml`. Note the runner OS, language/tool versions (`setup-node`, `setup-python`, `.nvmrc`, `.tool-versions`, `go.mod` toolchain), cache steps, services (Postgres, Redis), and which env vars and secrets each job reads. Find the matching local commands in the README, Makefile or `package.json` scripts.

## Step 1: Get the failure

- GitHub: `gh run list --branch <branch> --limit 5`, then `gh run view <run-id> --log-failed`. For a PR: `gh pr checks <num>`.
- GitLab: `glab ci view` / `glab ci trace <job-id>`, or the job log in the UI.
- Others: ask the dev to paste the failed step's log (the first error, not only the last line).

Find the first real error. The last line is usually "exit code 1"; the cause is above it.

## Step 2: Classify

- **Real failure**: a test or type/lint check fails because of code in this branch. Same failure on rerun.
- **Flaky**: passes on rerun with no change; timing, order dependence, shared state, real network, unseeded randomness, time zones. Check if the same test failed on other branches (`gh run list --workflow <name> --status failure`).
- **Env / secret**: `undefined` config, 401/403 from a service, "secret not found". Secrets are not available to PRs from forks.
- **Cache**: stale or corrupted dependency/build cache; failure disappears with a fresh cache or a changed key.
- **Version drift**: unpinned tool or dependency moved (`node: latest`, `ubuntu-latest` image bump, `^` ranges without a lockfile install, a new lint rule release). Compare versions in the passing and failing logs.
- **Infra**: runner out of disk/memory, service container not ready, rate limits, registry outage.

Check what changed: `git log <last-green-sha>..HEAD --oneline` and the diff of CI config and lockfiles.

## Step 3: Reproduce locally

Run the exact command the job runs, with the same versions and env:
- Same tool version (`nvm use`, `pyenv`, `asdf`) and a clean install from the lockfile (`npm ci`, `pnpm install --frozen-lockfile`, `pip install -r requirements.txt`, `go mod download`).
- Same env: `CI=true`, same `TZ`, same `NODE_ENV`/test settings, same DB service version.
- For order or parallel issues: run the full suite the way CI does, not one file.
- If it only fails on the runner, run the job locally (`act` for GitHub Actions) or add a temporary debug step in a branch, then remove it.

For a suspected flake, loop it: `for i in $(seq 1 20); do <test cmd> || break; done`.

## Step 4: Fix the root cause

- Real failure: fix the code or the test, whichever is wrong. If the test is wrong, say why in the PR.
- Flaky: remove the nondeterminism (fake timers, seeded data, await the right condition instead of sleeping, isolate shared state). A retry wrapper only with a ticket to remove it.
- Env/secret: add the missing var to CI config and `.env.example`; ask the dev to add the secret value. Never paste a secret into the config or logs.
- Cache: fix the cache key (include the lockfile hash and tool version), don't just disable caching.
- Drift: pin the version (lockfile, `.nvmrc`, explicit runner image, action SHA or tag) or update the code for the new version (`dependency-upgrade` if it's large).

## Step 5: Verify

Push and watch the run (`gh run watch`). Green once isn't enough for a flake: rerun the job 2-3 times. Report:

```
Cause: version drift - ubuntu-latest moved to 24.04, Postgres client 16 rejects old auth
Evidence: green run 3f2a1c used 22.04; failing run used 24.04 (job log line 41)
Fix: pin runs-on: ubuntu-22.04 in ci.yml; ticket to upgrade the auth config
Verified: 3 green runs on the branch
```

## Rules

- Never disable, skip, `continue-on-error`, `--passWithNoTests`, lower a coverage threshold, or delete a test to go green.
- Never print secrets or add them to config files; reference them from the CI secret store.
- Change CI config and app code in separate commits so either can be reverted.

Next: `debug` for a test failure you can't explain, `regression-postmortem` if a broken main shipped, `commit-message` for the fix.
