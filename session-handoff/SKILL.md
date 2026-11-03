---
name: session-handoff
description: Compact the current session into a handoff doc that another dev or agent can pick up cold: goal, current state, decisions, what is done and verified, open questions, next steps, exact commands and file paths. Saves it to a file and prints the path. Use when "hand this off", "write a handoff", "I'm stopping for today", "someone else will continue", "context is getting full", or before switching machines or agents.
---

# Session Handoff

Write down everything the next person needs so they never have to read this conversation. They start with the file, the repo, and nothing else.

## Step 1: Gather the facts

Collect from the session and the repo, not from memory alone:

1. Goal: the ticket or request, with its ID and link if there is one.
2. Repo state: run `git status`, `git branch --show-current`, `git log --oneline -10`, `git stash list`. Note uncommitted files and unpushed commits (`git log @{u}..` if there is an upstream).
3. What changed: `git diff --stat main...HEAD` (or the repo's default branch) plus uncommitted changes.
4. What was verified: which tests, builds, or manual checks ran, with the exact command and the result. If something was not run, say "not run".
5. Running things: dev servers, watchers, containers, background jobs, ports in use.
6. Decisions made and why, and dead ends tried (so nobody retries them).

## Step 2: Write the doc

Save to `docs/handoffs/YYYY-MM-DD-<short-topic>.md` if the repo keeps handoffs there, else `.handoff/YYYY-MM-DD-<short-topic>.md` at the repo root. Ask before committing it; handoffs often contain half-finished thinking.

```
# Handoff: ABC-412 invoice PDF timeouts
Date: 2026-11-03   Branch: fix/abc-412-pdf-timeout (2 commits unpushed)

## Goal
Invoice PDF export times out for orgs with 500+ lines. Ticket: ABC-412.

## State
Root cause found: images fetched per line, no cache. Fix half done.

## Done and verified
- Added image cache in pdf/render.py:40. `pytest tests/pdf -q` -> 18 passed.
## Done, not verified
- Batch fetch in pdf/images.py:12. Not run against staging.

## Decisions
- Cache in-process, not Redis: one worker per job (see thread in ABC-412).
## Dead ends
- Raising the timeout: masked the issue, reverted (commit 9c1e2aa).

## Open questions
- Does staging have a 500-line org? Ask QA.

## Next steps
1. Run `pytest tests/pdf -q` then `make e2e-pdf`.
2. Test on staging org 4411.
3. Open PR (pr-description).

## Files
pdf/render.py, pdf/images.py, tests/pdf/test_render.py
## Environment
`docker compose up db redis` must be running. No env changes.
```

## Step 3: Print the path

End by printing the absolute path of the file and a two-line summary: where things stand and the very next step.

## Rules

- Exact commands and file paths, copied from what actually ran. No "run the tests".
- Separate verified from not verified. Never mark something verified that was not run in this session.
- Never put secrets, tokens, or full `.env` contents in the doc. Name the variable, not its value.
- Keep it under 80 lines. Link the ticket, PR or ADR instead of copying them.
- Write it so it works for a person or an agent: no "as we discussed", no pronouns without a subject.

Next: `pr-description` if the work is ready to open, or `verify-done` for whoever picks it up.
