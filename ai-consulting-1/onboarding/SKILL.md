---
name: onboarding
description: Get a new developer productive on a client's repos — verified local setup per repo, the conventions that matter, and a good first-week task. Use when someone says "I'm new here", "how do I set this up", "how do I run this project", or when a dev joins a client project.
---

# Onboarding

Goal: by the end, the dev has every repo running locally, knows the 10 conventions that will come up in review, and has a real first task.

## Step 1: Who and what

Ask, in one message: which repos they need (or "all"), their OS, and whether they have Docker. Read the repo map (`../repo-map.md` or `docs/repo-map.md`) for the list of repos and how they connect. If there's no map, note it; you'll build it at the end.

## Step 2: Setup, verified, per repo

For each repo, derive the steps from what's actually there, in this order of trust: `docker-compose.yml` / `Makefile` / CI config > `README` > guessing. CI config is often the most accurate record of what's needed to run tests.

Cover:
- Runtime versions (`.python-version`, `pyproject.toml`, `runtime.txt`, `.nvmrc`)
- Install (`uv sync`, `poetry install`, `pip install -r requirements/dev.txt`, ...)
- Env vars: copy from `.env.example`; list which ones need a real value and who to ask for them. Never paste secret values into chat or files.
- Services: Postgres, Redis, Celery worker, etc.
- DB: `python manage.py migrate`, seed/fixture commands, creating a superuser
- Run: `runserver` / `docker compose up`, and the URL to open
- Tests: the exact command CI runs

Run each step with the dev where you can, and fix as you go. When a README step is wrong or missing, note it. At the end, offer a PR that fixes the README with what actually worked.

Done when, for each repo: the app starts, one page or endpoint responds, and the test suite runs (passing, or with known failures written down).

## Step 3: Conventions that matter

Pull these from the "How we do X here" section of the repo map, or from reading 2-3 representative apps if there's no map. Keep it to what a reviewer will actually flag:

- Branch naming, commit message format, PR template, who reviews
- Where business logic goes (services vs models vs serializers)
- Permissions pattern and queryset scoping
- Test style: pytest-django, factories, where `conftest.py` helpers are
- Migration rules (see `django-migrations`)
- Linters/formatters and pre-commit hooks; install hooks now

Write it as a one-page `docs/onboarding.md` in the main repo if one doesn't exist, or update the existing one.

## Step 4: First-week task

Pick one, in this order:
1. A Jira/GitHub issue labelled `good first issue`, `onboarding` or similar (check with the Atlassian MCP or `gh issue list --label`).
2. A small bug in a well-tested app.
3. Adding characterization tests to an untested area the team is about to change. Useful work, low risk, and it teaches the codebase.

Explain why that task, which files they'll touch, and the route: `ask-imogen` will take it from there.

## Step 5: Map

If no repo map existed, run `repo-map` now. If one exists, show them its Connections section; that diagram is the fastest way to understand the system.
