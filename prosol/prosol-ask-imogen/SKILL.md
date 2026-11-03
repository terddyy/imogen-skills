---
name: prosol-ask-imogen
description: Front door for the Imogen Prosol kit (Prosol Django projects). Use in a Prosol Django repo when a developer describes what they're doing in plain words ("client wants a feature", "I need to build this ticket", "this page is slow", "something broke", "I'm new here", "ready to open a PR") or asks "how do we do X here" / "where does X live". Figures out the situation, recommends the right skill or chain of skills, and answers codebase questions from the repo map.
---

# Ask Imogen (Prosol)

The router. Devs don't need to remember 20 skill names. They say what they're doing; you work out the situation and point them at the right skill, or chain of skills, then start it.

## Step 0: Check you're in a Prosol repo

This kit is only for Prosol's Django codebases. Before routing, confirm Django: `manage.py` at the repo root (or one level down) and `django` in `requirements*.txt` / `pyproject.toml`. If the repo isn't Django, or the work is clearly outside Prosol, say in one line that this kit doesn't cover it, then help directly without routing to a skill.

## Step 1: Figure out the situation

Read the dev's message. If it's a "where/how" question, go to Step 3. Otherwise, match it to one of the situations below. If two fit, pick the one closest to what they'll do *next*. Only ask a clarifying question if you genuinely can't tell (one question, not a form).

Useful signals to check quickly before routing:

- Current branch and `git status`: uncommitted work points to "ready to open a PR" or "something broke".
- A Jira key in the message (e.g. `ABC-123`): "build this ticket".
- A file or model named in the message: check the repo map for whether it's shared with other repos.

## Step 2: Recommend a route

| Dev says something like... | Route |
| --- | --- |
| "Client wants a new feature" | `prosol-prd-writer` → `prosol-jira-tickets` → `prosol-impact-analysis` |
| "I need to build this ticket" / a Jira key or link | `prosol-jira-build` → `prosol-code-quality` → `prosol-pr-description` |
| "I need to change this model / endpoint" | `prosol-impact-analysis` → `prosol-characterization-tests` → `prosol-safe-change` → `prosol-django-migrations` |
| "This touches the other repo" | `prosol-impact-analysis` → `prosol-cross-repo-change` → `prosol-contract-tests` |
| "This page / endpoint is slow" | `prosol-perf-audit` → `prosol-query-optimizer` → `prosol-caching-strategy` |
| "Something broke after my change" | `prosol-regression-postmortem` → `prosol-characterization-tests` |
| "I'm scared to touch this code" | `prosol-characterization-tests` → `prosol-safe-change` |
| "Where does X live? How do we do Y?" | answer directly from `prosol-repo-map` (Step 3) |
| "I'm new here" | `prosol-onboarding` → `prosol-repo-map` |
| "Ready to open a PR" | `prosol-code-quality` → `prosol-pr-description` |
| "Write tests for this" | `prosol-test-writer` |
| "Should we cache this?" | `prosol-caching-strategy` |
| "Write release notes" | `prosol-regression-postmortem` (release notes mode) |

Adjust the chain to the actual work, and say why you dropped a step:

- No model or schema change: drop `prosol-django-migrations`.
- Code is already well tested: drop `prosol-characterization-tests`.
- Single repo and the repo map shows no consumers of what's changing: drop `prosol-cross-repo-change` and `prosol-contract-tests`.
- Ticket only touches templates or config: `prosol-django-feature` is overkill; go straight to the change and `prosol-test-writer`.
- Ticket has mockups or screenshots attached: always `prosol-jira-build`, even if it looks small. It's the only route that checks the UI against the images.

Reply in this shape, short:

```
Looks like: <situation in one line>
Route: prosol-impact-analysis → prosol-characterization-tests → prosol-safe-change → prosol-django-migrations
Why: <one line per step, only where it isn't obvious>
Start with prosol-impact-analysis now?
```

On a yes, run the first skill. When it finishes, say which skill is next and wait for the dev to continue, so they can stop between steps.

## Step 3: Answer "where / how" questions

Find the repo map. Look in this order:

1. `repo-map.md` in the parent folder of the current repo (the workspace that holds all client repos)
2. `docs/repo-map.md` in the current repo

If it exists, answer from it and cite the section. Then verify against the code (the map can be stale): open the file it points to and confirm. If the map was wrong, say so and offer to run `prosol-repo-map` in refresh mode.

If there's no map, answer by searching the code directly, and suggest running `prosol-repo-map` once so the next question is instant.

Good answers name the file and the pattern: "Permissions live in `core/permissions.py`; views use `IsOrgMember` + `get_queryset` filtered by `request.user.org`. Example: `billing/views.py:42`."

## Rules

- Recommend, then wait for a go-ahead before running a chain. Don't silently run five skills.
- Never invent a skill name. The kit is: `prosol-ask-imogen`, `prosol-prd-writer`, `prosol-jira-tickets`, `prosol-jira-build`, `prosol-impact-analysis`, `prosol-repo-map`, `prosol-onboarding`, `prosol-django-feature`, `prosol-safe-change`, `prosol-django-migrations`, `prosol-cross-repo-change`, `prosol-characterization-tests`, `prosol-contract-tests`, `prosol-test-writer`, `prosol-perf-audit`, `prosol-query-optimizer`, `prosol-caching-strategy`, `prosol-code-quality`, `prosol-pr-description`, `prosol-regression-postmortem`.
- If the request is outside the kit (infra, design work with no ticket behind it, etc.), say so and just help directly.
