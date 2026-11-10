---
name: verify-done
description: Prove work is finished before saying so. Runs the repo's build, type-check, linter and tests, exercises the actual feature (CLI run, curl, or browser), checks each acceptance criterion, and reports the evidence as commands and output. Use before saying "done", before opening a PR, when someone asks "does it work?", "is this finished?", "did you test it?", or at the end of any build or fix task.
---

# Verify Done

"Done" means you ran it and saw it work. Every claim in the final report points at a command you ran and what it printed. "Should work" is not a status.

## Step 0: Read the stack

Find the checks this repo uses, in this order: CI config (`.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`), then package.json scripts / Makefile / `justfile` / `Taskfile.yml`, then README. CI is the source of truth: run what CI runs. Typical set:

- Build: `npm run build`, `go build ./...`, `cargo build`, `mvn -q package -DskipTests`
- Types: `tsc --noEmit`, `mypy`/`pyright`, (compiled languages get this from the build)
- Lint/format: `npm run lint`, `ruff check . && ruff format --check .`, `golangci-lint run`, `cargo clippy`
- Tests: `npm test`, `pytest`, `go test ./...`

## Step 1: Restate the acceptance criteria

Pull the criteria from the ticket, PRD, issue, or the dev's request (Jira via Atlassian MCP or REST with JIRA_URL / JIRA_EMAIL / JIRA_API_TOKEN; never print the token). Write them as a checklist. If there are none, write down what "working" means and confirm it with the dev before verifying against it.

## Step 2: Run the static checks

Run build, type-check, lint, and format check on the whole project (or the affected packages in a monorepo). Fix what your change broke. If something was already failing on the default branch, show that (`git stash` and rerun, or check the last CI run) and report it as pre-existing instead of hiding it.

## Step 3: Run the tests

1. Tests for the changed code first, then the full suite if it runs in reasonable time.
2. New behavior has at least one test that fails without the change. If there is none, write it (`test-writer`) or say plainly that it is missing.
3. Read the summary: count passed, failed, skipped. New skips or `.only` left in the code count as failures.

## Step 4: Exercise the real thing

Tests are not the feature. Run it the way a user or caller would:

- **API**: start the server, hit it, show status and body.
  `curl -s -X POST localhost:3000/api/invoices/42/void -H "Authorization: Bearer $TEST_TOKEN" | jq`
- **CLI / job**: run the command with realistic input and show the output and exit code (`echo $?`).
- **UI**: open the page (browser tool, Playwright script, or ask the dev to click through), take a screenshot, check the console for errors.
- **Data change**: query the DB or API afterwards to show the state changed, and that nothing else did.

Try one unhappy path too: bad input, wrong user, empty state.

## Step 5: Report the evidence

```
ABC-123 void invoices: verified

[x] Admin can void an issued invoice
    curl ... -> 200 {"id":42,"status":"void"}
[x] Member gets 403          curl ... -> 403
[x] Tests                    npm test -> 214 passed, 0 failed (was 209)
[x] Build / types / lint     npm run build, tsc --noEmit, npm run lint -> clean
[ ] Void email               NOT verified: no SMTP sandbox locally. Ask QA to check on staging.
Pre-existing: lint warning in src/legacy/report.ts (also on main)
```

Each line is a criterion with the command and the relevant output. Anything not verified is listed as not verified, with the reason.

## Rules

- Never say "done", "fixed", or "works" without the evidence above. Never write "should work".
- Implementation screenshots, recordings and QA or validation notes never go in git. Capture outside the repo, stage by explicit path, check `git diff --cached --name-status`, and delete captures you made before committing. To share one, give the dev its outside-repo path to upload to the PR or ticket.
- Never claim a check you did not run, and never paraphrase a failure as a pass.
- Do not disable a lint rule, skip a test, or loosen a type to get green. Fix it or report it.
- If you cannot run something (no DB, no credentials), say so and say who can.

Next: `pr-description` to open the PR, `ci-fix` if CI disagrees with your local run.
