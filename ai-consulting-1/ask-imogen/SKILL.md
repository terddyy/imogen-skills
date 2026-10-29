---
name: ask-imogen
description: Front door for the Imogen dev kit. Use when a developer describes what they're doing in plain words ("client wants a feature", "I need to build this ticket", "this page is slow", "something broke", "I'm new here", "ready to open a PR") or asks "how do we do X here" / "where does X live". Figures out the situation, recommends the right skill or chain of skills, and answers codebase questions from the repo map.
---

# Ask Imogen

The router. Devs don't need to remember 19 skill names. They say what they're doing; you work out the situation and point them at the right skill, or chain of skills, then start it.

## Step 1: Figure out the situation

Read the dev's message. If it's a "where/how" question, go to Step 3. Otherwise, match it to one of the situations below. If two fit, pick the one closest to what they'll do *next*. Only ask a clarifying question if you genuinely can't tell (one question, not a form).

Useful signals to check quickly before routing:

- Current branch and `git status`: uncommitted work points to "ready to open a PR" or "something broke".
- A Jira key in the message (e.g. `ABC-123`): "build this ticket".
- A file or model named in the message: check the repo map for whether it's shared with other repos.

## Step 2: Recommend a route

| Dev says something like... | Route |
| --- | --- |
| "Client wants a new feature" | `prd-writer` → `jira-tickets` → `impact-analysis` |
| "I need to build this ticket" | `impact-analysis` → `django-feature` → `test-writer` → `pr-description` |
| "I need to change this model / endpoint" | `impact-analysis` → `characterization-tests` → `safe-change` → `django-migrations` |
| "This touches the other repo" | `impact-analysis` → `cross-repo-change` → `contract-tests` |
| "This page / endpoint is slow" | `perf-audit` → `query-optimizer` → `caching-strategy` |
| "Something broke after my change" | `regression-postmortem` → `characterization-tests` |
| "I'm scared to touch this code" | `characterization-tests` → `safe-change` |
| "Where does X live? How do we do Y?" | answer directly from `repo-map` (Step 3) |
| "I'm new here" | `onboarding` → `repo-map` |
| "Ready to open a PR" | `code-quality` → `pr-description` |
| "Write tests for this" | `test-writer` |
| "Should we cache this?" | `caching-strategy` |
| "Write release notes" | `regression-postmortem` (release notes mode) |

Adjust the chain to the actual work, and say why you dropped a step:

- No model or schema change: drop `django-migrations`.
- Code is already well tested: drop `characterization-tests`.
- Single repo and the repo map shows no consumers of what's changing: drop `cross-repo-change` and `contract-tests`.
- Ticket only touches templates or config: `django-feature` is overkill; go straight to the change and `test-writer`.

Reply in this shape, short:

```
Looks like: <situation in one line>
Route: impact-analysis → characterization-tests → safe-change → django-migrations
Why: <one line per step, only where it isn't obvious>
Start with impact-analysis now?
```

On a yes, run the first skill. When it finishes, say which skill is next and wait for the dev to continue, so they can stop between steps.

## Step 3: Answer "where / how" questions

Find the repo map. Look in this order:

1. `repo-map.md` in the parent folder of the current repo (the workspace that holds all client repos)
2. `docs/repo-map.md` in the current repo

If it exists, answer from it and cite the section. Then verify against the code (the map can be stale): open the file it points to and confirm. If the map was wrong, say so and offer to run `repo-map` in refresh mode.

If there's no map, answer by searching the code directly, and suggest running `repo-map` once so the next question is instant.

Good answers name the file and the pattern: "Permissions live in `core/permissions.py`; views use `IsOrgMember` + `get_queryset` filtered by `request.user.org`. Example: `billing/views.py:42`."

## Rules

- Recommend, then wait for a go-ahead before running a chain. Don't silently run five skills.
- Never invent a skill name. The kit is: `ask-imogen`, `prd-writer`, `jira-tickets`, `impact-analysis`, `repo-map`, `onboarding`, `django-feature`, `safe-change`, `django-migrations`, `cross-repo-change`, `characterization-tests`, `contract-tests`, `test-writer`, `perf-audit`, `query-optimizer`, `caching-strategy`, `code-quality`, `pr-description`, `regression-postmortem`.
- If the request is outside the kit (frontend styling, infra, etc.), say so and just help directly.
