---
name: regression-postmortem
description: When something broke after a change, find the commit and the root cause (git log, pickaxe search, bisect), reproduce it as a failing test, fix it at the root, and write a short blameless postmortem. Also drafts release notes from the commits between two tags or deploys. Use for "something broke after my change", "this worked last week", "prod is throwing X since the deploy", "what caused this", or "write release notes".
---

# Regression Postmortem

Find out why it broke, turn that into a test so it cannot silently break again, then write it up so the team learns something. Two modes: **postmortem** (default) and **release notes**.

## Postmortem mode

### Step 0: Read the stack

Find the test command and runner (manifest, package.json scripts, Makefile, CI config) so you can write the reproduction in the repo's style, and find where errors are reported (Sentry, logs, APM).

### Step 1: Pin the symptom

Get the exact error and stack trace (error tracker link or log lines), the endpoint, page, or command, who is affected (everyone, one tenant, one role, one browser), when it started, and what was deployed around then. If it is a live production incident, mitigation comes first (revert the deploy, turn the flag off). Ask whether that is done before investigating.

### Step 2: Reproduce

Reproduce before guessing. Best form is a failing test at the highest seam that shows the symptom (an API test for an endpoint bug, an e2e test for a UI flow). If it will not reproduce, list what differs between local and the failing environment (data, config, env vars, versions, feature flags, background job vs inline) and narrow from there. Use `debug` if it stays unclear.

### Step 3: Find the change

Fastest first:

```bash
git log --oneline --since="7 days ago" -- <suspect paths>
git log -S "<field_or_function_name>" --oneline     # commits that added or removed the string
git log -p -L :<function>:<path/to/file>            # history of one function
git diff <last-good-deploy-sha> <bad-sha> --stat
```

With a known good and bad commit and a failing test, bisect:

```bash
git bisect start <bad> <good>
git bisect run npx vitest run path/to/regression.test.ts   # or: pytest path -x -q / go test ./pkg -run TestX
git bisect reset
```

Check lockfile and dependency diffs too (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `go.sum`, `Cargo.lock`), plus migrations and config/env changes. Many "nothing changed" regressions are a library upgrade or a config flip.

### Step 4: Root cause, then fix

State the root cause in one or two mechanical sentences: "Commit abc123 moved the void email into an ORM save hook; the nightly job uses bulk update, which skips hooks, so invoices voided by the job never send the email." Not "a bug in the hook".

1. Keep the reproduction test as the regression guard. Confirm it fails before the fix.
2. Fix the root cause, not the symptom. If the right fix is big, ship a small safe fix now and ticket the proper one (`jira-tickets`).
3. Search for the same mistake elsewhere. Same bug in other places gets the same fix or a ticket.
4. If the area around it is untested, run `characterization-tests` before changing more.
5. Run `verify-done` on the fix.

### Step 5: Write the postmortem

Short and blameless: about the change and the gaps, never the person. Save to `docs/postmortems/YYYY-MM-DD-<slug>.md`, or wherever the team keeps them:

```markdown
# <What broke>, YYYY-MM-DD

Impact: who or what was affected, for how long
Detected by: error alert / client report / ...
Root cause: <mechanical explanation, link to the commit>
Fix: <PR link>
Why it got through: no test for the bulk path; hook side effect not visible in review
Prevent: regression test added (path); ABC-140 to move side effects out of hooks
Timeline (prod incidents only): HH:MM deployed, HH:MM first error, HH:MM reverted, HH:MM fixed
```

## Release notes mode

1. Get the range: two tags (`git tag --sort=-creatordate | head`), or last deployed sha to HEAD.
2. `git log --oneline --no-merges <from>..<to>` plus merged PR titles (`gh pr list --state merged --search "merged:>=YYYY-MM-DD"`).
3. Group into **New**, **Improved**, **Fixed**, **Breaking / action needed** (API changes consumers must handle, migrations with deploy steps, removed fields, new env vars). Skip refactors and test-only changes unless asked.
4. Ask the audience. Client-facing: plain language, no internals. Internal: ticket keys, PR links, migration notes.
5. Show the draft. Do not publish anywhere without the dev's go-ahead.

## Rules

- No fix without a test that failed before it.
- Do not name or blame people in the write-up.
- If the root cause is still a guess, say so and list what would confirm it.

Next: `pr-description` for the fix PR.
