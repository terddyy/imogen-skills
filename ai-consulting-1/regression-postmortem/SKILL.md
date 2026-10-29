---
name: regression-postmortem
description: When something broke after a change, find the commit and root cause, reproduce it as a failing test, fix it, and write a short blameless postmortem. Also drafts release notes from the commits between two tags or deploys. Use for "something broke after my change", "this worked last week", "prod is throwing X since the deploy", or "write release notes".
---

# Regression Postmortem

Find out why it broke, turn that into a test so it can't silently break again, then write it up so the team learns something. Two modes: **postmortem** (default) and **release notes**.

## Postmortem mode

### Step 1: Pin the symptom

Get specifics: the exact error/traceback (Sentry link or log lines), the endpoint or page, who's affected (all users, one org, one role), when it started, and what was deployed around then. If it's an active production incident, the first move is mitigation (revert the deploy, toggle the flag off). Ask whether that's done before investigating.

### Step 2: Reproduce

Reproduce locally before guessing at causes. Best form is a failing test at the highest seam that shows the symptom (API test for an endpoint bug). If you can't reproduce, list what's different between local and the failing environment (data, settings, env vars, versions, Celery vs sync) and narrow down from there.

### Step 3: Find the change

Fastest first:

```bash
git log --oneline --since="7 days ago" -- <suspect paths>
git log -S "<field_or_function_name>" --oneline        # commits that added/removed the string
git log -p -L :<function_name>:<path/to/file.py>        # history of one function
```

If that doesn't find it and you have a good and a bad commit, bisect with the failing test:

```bash
git bisect start <bad> <good>
git bisect run pytest path/to/test_regression.py -x -q
git bisect reset
```

Check migrations and dependency bumps too (`requirements*.txt`, `poetry.lock`, `uv.lock` diffs); a lot of "nothing changed" regressions are a library upgrade.

### Step 4: Root cause, then fix

State the root cause in one or two sentences, mechanically: "Commit abc123 moved the void email into a post_save signal; `bulk_update` in the nightly job doesn't fire signals, so voided invoices from the job never send the email." Not "a bug in the signal".

Then:
1. Keep the reproduction test (it's the regression guard). Make sure it fails before the fix.
2. Fix at the root cause, not the symptom. If the right fix is big, ship a small safe fix now and ticket the proper one.
3. Look for the same mistake elsewhere (`grep` for the pattern). Same bug in other places = same fix, or a ticket.
4. If the area around it is untested, add `characterization-tests` before going further.

### Step 5: Write the postmortem

Short, blameless (about the change and the gaps, not the person). Save to `docs/postmortems/YYYY-MM-DD-<slug>.md`, or post where the team keeps them:

```markdown
# <What broke>, YYYY-MM-DD

Impact: who/what was affected, for how long
Detected by: Sentry alert / client report / ...
Root cause: <mechanical explanation, linking the commit>
Fix: <PR link>
Why it got through: no test for bulk path; signal side effect not visible in review
Prevent: regression test added (path); ticket ABC-140 to move side effects out of signals
Timeline (only if it was a prod incident): HH:MM deployed, HH:MM first error, HH:MM reverted, HH:MM fixed
```

## Release notes mode

1. Get the range: two tags (`git tag --sort=-creatordate | head`), or last deploy sha → HEAD.
2. `git log --oneline --no-merges <from>..<to>` and the merged PR titles (`gh pr list --state merged --search "merged:>=YYYY-MM-DD"`).
3. Group into **New**, **Improved**, **Fixed**, **Breaking / action needed** (API changes consumers must handle, migrations with deploy steps, removed fields, new env vars). Skip pure refactors and test-only changes unless asked.
4. Write each line for the audience. Ask: client-facing (plain language, no internals) or internal (Jira keys, PR links, migration notes)?
5. Show the draft. Don't publish anywhere without the dev's go-ahead.

## Rules

- No fix without a test that failed before it.
- Don't name or blame people in the write-up.
- If the root cause is still a guess, say so explicitly and list what would confirm it.
