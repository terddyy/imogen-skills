---
name: ask-imogen
description: Front door for the Imogen dev kit, on any tech stack. Use when a developer describes what they're doing in plain words ("client wants a feature", "build this ticket", "this page is slow", "something broke", "CI is red", "I'm new here", "ready to open a PR", "upgrade React", "the UI looks off") or asks "how does X work" / "where does X live". Reads the stack, figures out the situation, recommends the right skill or chain of skills, and answers codebase questions from the repo map. Hands Django repos to prosol-ask-imogen when the Prosol kit is installed.
---

# Ask Imogen

The router. Devs don't need to remember 40-odd skill names. They say what they're doing; you read the stack, work out the situation, point them at the right skill or chain of skills, then start it.

## Step 0: Read the stack

Look at the repo root before routing. Use manifests and lockfiles: `package.json` + lockfile, `pyproject.toml` / `requirements*.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `pom.xml` / `build.gradle`, `*.csproj`, `pubspec.yaml`. Note the framework, the test runner, and whether there's a database/migration tool or a UI. This decides which steps in a route apply.

If `prosol-ask-imogen` is also installed and this is a Django repo (`manage.py` at the root or one level down, and `django` in `requirements*.txt` / `pyproject.toml`), hand off to it in one line ("Django repo, switching to prosol-ask-imogen") and stop. Otherwise continue with this kit. Never suggest installing the Prosol kit; it's only for Prosol's team.

## Step 1: Figure out the situation

Read the dev's message. If it's a "where/how" question, go to Step 3. Otherwise match it to a row below. If two fit, pick the one closest to what they'll do *next*. Ask one clarifying question only if you genuinely can't tell.

Quick signals worth checking:

- `git status` and the current branch: uncommitted work points to "ready to open a PR" or "something broke".
- A Jira key (`ABC-123`) means "build this ticket". A GitHub issue (`#123`, issue URL) means `imogen-fix-issues`.
- A file or module named in the message: check the repo map for other repos that consume it.

## Step 2: Recommend a route

| Dev says something like... | Route |
| --- | --- |
| "Client wants a new feature" / "I have an idea" | `grill-plan` → `prd-writer` → `jira-tickets` (or `imogen-issue` for GitHub) → `impact-analysis` |
| "Build this ticket" / a Jira key | `jira-build` → `verify-done` → `code-quality` → `pr-description` |
| "Fix this GitHub issue" / `#123` | `imogen-fix-issues` |
| "Build this feature" (no ticket) | `feature-build` (with `test-first`) → `verify-done` → `code-quality` → `pr-description` |
| "Change this model / endpoint / schema" | `impact-analysis` → `characterization-tests` → `safe-change` → `db-migrations` |
| "Design a new API / endpoint" | `api-design` → `feature-build` → `contract-tests` |
| "This touches the other repo" | `impact-analysis` → `cross-repo-change` → `contract-tests` |
| "This page / endpoint is slow" | `perf-audit` → `query-optimizer` → `caching-strategy` |
| "Bug" / "error" / "this test fails" | `debug` → `verify-done` |
| "Something broke after my change / the deploy" | `regression-postmortem` → `characterization-tests` |
| "CI is red" | `ci-fix` |
| "Refactor this" / "I'm scared to touch this" | `characterization-tests` → `refactor-plan` → `safe-change` |
| "This code is a mess" / "how should this be structured" | `improve-architecture` → `refactor-plan` → `adr` |
| "Upgrade X" / "bump dependencies" | `dependency-upgrade` → `verify-done` |
| "Is this secure?" | `security-audit` |
| "The UI looks off" / "polish this page" | `ui-polish` → `accessibility-audit` |
| "Not sure X will work" / "X or Y?" | `spike` → `adr` |
| "Poke holes in my plan" | `grill-plan` → `adr` |
| "How does this work?" | `explain-code` |
| "Where does X live?" / "How do we do Y here?" | answer from the repo map (Step 3) |
| "I'm new here" | `onboarding` → `repo-map` |
| "Get this running locally" / "add Docker / pre-commit" | `dev-env-setup` |
| "Write tests for this" | `test-writer` (`e2e-tests` for user journeys) |
| "Write the docs / README" | `docs-writer` |
| "Commit this" | `commit-message` |
| "Ready to open a PR" | `verify-done` → `code-quality` → `pr-description` |
| "Ready to deploy" | `deploy-checklist` |
| "Write release notes" | `regression-postmortem` (release notes mode) |
| "Big task, work on it while I'm away" | `overnight-task-runner` |
| "I'm stopping" / "hand this to someone" | `session-handoff` |

Fit the chain to the actual work, and say why you dropped a step:

- No database, or no schema change: drop `db-migrations`.
- Code is already well tested: drop `characterization-tests`.
- Single repo, and the repo map shows nothing consumes what's changing: drop `cross-repo-change` and `contract-tests`.
- No UI in the change: drop `ui-polish`, `accessibility-audit` and `e2e-tests`.
- UI work and `impeccable` is installed: use its commands (`critique`, `audit`, `polish`) in place of `ui-polish`. For palettes, fonts or a new design system, use `ui-ux-pro-max` if it's installed.
- Ticket has mockups or screenshots: always `jira-build`, even if it looks small. It's the only route that checks the UI against the images.

Reply in this shape, short:

```
Stack: <framework, test runner, db/migrations, UI or not>
Looks like: <situation in one line>
Route: impact-analysis → characterization-tests → safe-change → db-migrations
Why: <one line per step, only where it isn't obvious>
Start with impact-analysis now?
```

On a yes, run the first skill. When it finishes, say which skill is next and wait, so the dev can stop between steps.

## Step 3: Answer "where / how" questions

Find the repo map, in this order:

1. `repo-map.md` in the parent folder of the current repo (the workspace that holds all the repos)
2. `docs/repo-map.md` in the current repo

If it exists, answer from it and cite the section. Then verify against the code, because the map can be stale: open the file it points to and confirm. If the map was wrong, say so and offer to run `repo-map` in refresh mode.

If there's no map, search the code directly, and suggest running `repo-map` once so the next question is instant.

A good answer names the file and the pattern: "Auth checks live in `src/server/auth.ts`. Route handlers call `requireUser()` and then scope queries by `user.orgId`. Example: `src/app/api/invoices/route.ts:18`."

## Rules

- Recommend, then wait for a go-ahead before running a chain. Don't silently run five skills.
- Never invent a skill name. The kit is: `ask-imogen`, `grill-plan`, `prd-writer`, `jira-tickets`, `jira-build`, `imogen-issue`, `impact-analysis`, `adr`, `spike`, `repo-map`, `onboarding`, `explain-code`, `feature-build`, `test-first`, `safe-change`, `db-migrations`, `api-design`, `cross-repo-change`, `imogen-fix-issues`, `overnight-task-runner`, `characterization-tests`, `contract-tests`, `test-writer`, `e2e-tests`, `debug`, `verify-done`, `security-audit`, `refactor-plan`, `improve-architecture`, `dependency-upgrade`, `code-quality`, `perf-audit`, `query-optimizer`, `caching-strategy`, `ui-polish`, `accessibility-audit`, `docs-writer`, `commit-message`, `pr-description`, `session-handoff`, `ci-fix`, `dev-env-setup`, `deploy-checklist`, `regression-postmortem`. Hand-offs outside it: `prosol-ask-imogen` and, if installed, `impeccable` and `ui-ux-pro-max`.
- If the request is outside the kit (infra provisioning, pure design work, etc.), say so and help directly.
