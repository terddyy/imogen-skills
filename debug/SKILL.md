---
name: debug
description: Track down the root cause of a bug in a fixed order: get a reliable repro, read the actual error, rank hypotheses, test them one at a time, fix the cause, add a regression test, and remove the debug code. Covers runtime errors, wrong output, flaky tests, and "works locally but not in prod". Use when "something broke", "this throws", "this test is flaky", "it works on my machine", "why is this returning X", or a bug ticket lands with only a stack trace.
---

# Debug

Find the cause before you change anything. A fix you can't explain is a guess, and guesses come back as regressions.

## Step 0: Read the stack

Find the manifest (package.json + lockfile, pyproject.toml, go.mod, Cargo.toml, Gemfile, pom.xml, ...) and the repo's own test and run commands (README, Makefile, package.json scripts, CI config). Use those exact commands throughout. If a repo map exists (`../repo-map.md` or `docs/repo-map.md`), use it to find the area, then check it against the code.

## Step 1: Get a reliable repro

Write down the expected vs the actual result, then get one command that shows the failure:
- Best: a failing test (`vitest run path -t "name"`, `pytest path::test_name`, `go test ./pkg -run TestName`).
- Otherwise: a script, a `curl` call, or exact UI steps with the input data.
- Flaky: run it in a loop until you know the failure rate (`for i in $(seq 50); do <cmd> || break; done`, `pytest --count=50` with pytest-repeat, `go test -count=50`). Also try a random order or a single worker.
- Prod only: get the exact request, user/tenant, timestamp, release version and the log or trace lines. Ask the dev to paste them.

No repro yet? Say so, and collect more evidence before you edit any code.

## Step 2: Read the actual error

Read the full stack trace, not just the last line. Find the first frame in this repo's code (skip library frames), open that file at that line, and read the code around it. Check `git log -p --since=<last known good> -- <file>` for recent changes there.

## Step 3: Rank hypotheses

List 2 to 4 causes that fit every symptom, most likely first, each with a cheap test that would rule it in or out:

```
1. user.org is null for invited users (fits: only new accounts fail)   test: log org_id at handler entry
2. cache returns a stale shape after the deploy                       test: bypass cache, rerun
3. race between the save and the queued job                            test: add a 2s delay before the enqueue
```

Usual suspects by symptom:
- **Flaky:** shared state between tests, test order, time/timezone, randomness without a seed, real network, async work not awaited, port or file collisions under parallel runs.
- **Works locally, not in prod:** env vars or config, a different dependency version (lockfile not used in the build), data volume or shape, file system case sensitivity, timezone/locale, missing migration, build step or feature flag difference, multiple instances where local runs one.
- **Started recently:** `git bisect start <bad> <good>` then `git bisect run <repro cmd>`.

## Step 4: Test one hypothesis at a time

Change one thing per run. Use the cheapest tool: a log line with a unique prefix (`DEBUG-ABC123`), a debugger breakpoint, a narrower test, bisect. Record what each run showed. When a result contradicts the hypothesis, drop it and go to the next one. Don't keep patching around it.

## Step 5: Fix the root cause

Fix where the bad value or state is created, not where it finally blows up. If the fault is in shared code, fix it there and check every caller (`impact-analysis` when there are many). A try/except or null check that hides the error is not a fix unless the null is a valid state.

## Step 6: Lock it and clean up

1. Turn the repro into a regression test that fails without the fix and passes with it. Run it before and after to prove both.
2. Run the related test suite.
3. Remove every debug log, breakpoint and temporary delay: `git diff | grep -n "DEBUG-"`.

Report:

```
Cause: invited users have no org until first login; handler assumed org was set (api/handlers/invite.ts:41)
Fix: resolve org from the invite record at the same spot
Test: invite.test.ts "accepts invite before first login" (failed before, passes now)
Not checked: prod data for users already stuck in this state
```

## Rules

- No fix without a repro, or an explicit note that you couldn't get one and what evidence you used instead.
- One change per experiment. Revert the experiments that didn't pan out.
- Don't mark a flaky test as skipped or add retries as the fix. Find out why it flakes.
- Never debug against production data or run writes there without the dev saying it's OK.

Next: `verify-done` to confirm the fix end to end; `regression-postmortem` if it escaped to prod.
