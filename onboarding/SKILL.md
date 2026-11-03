---
name: onboarding
description: Get a new developer productive on a project, on any stack - verified local setup for each repo, the conventions reviewers will flag, and a real first-week task. Use when someone says "I'm new here", "how do I set this up", "how do I run this project", "onboard me", or when a dev joins a client project.
---

# Onboarding

Done means: every repo the dev needs runs locally, they know the handful of conventions that come up in review, and they have a real first task.

## Step 0: Read the stack

Per repo, read the manifests and lockfiles (`package.json` + `pnpm-lock.yaml`/`yarn.lock`/`package-lock.json`/`bun.lockb`, `pyproject.toml`/`requirements*.txt`, `go.mod`, `Gemfile`, `pom.xml`, `*.csproj`, ...) and the runtime pins (`.nvmrc`, `.node-version`, `.python-version`, `.tool-versions`, `rust-toolchain.toml`, the `engines` field).

## Step 1: Who and what

Ask in one message: which repos they need (or "all"), their OS, and whether they have Docker. Read the repo map (`repo-map.md` in the parent folder, or `docs/repo-map.md`) for the repo list and how they connect. No map: note it; you'll build one at the end.

## Step 2: Setup, verified, per repo

Derive the steps from what's in the repo, in this order of trust: `.devcontainer/`, `docker-compose*.yml`, `Makefile`/`justfile`/package scripts and CI config, then README, then guessing. CI is often the most accurate record of what the tests need.

Cover:
- Runtime versions, and the version manager the repo expects (nvm, pyenv, asdf, mise).
- Install with the package manager that matches the lockfile (`pnpm install`, `uv sync`, `bundle install`, `go mod download`).
- Env vars: copy `.env.example`; list which ones need a real value and who to ask. Never paste secret values into chat or files.
- Services: database, cache, queue, workers, local emulators. Prefer the compose file if there is one.
- Database: migrate and seed with the repo's own commands; create a local admin user if the app needs one.
- Run: the dev command, and the URL or port to open.
- Tests and lint: the exact commands CI runs.

Run each step with the dev and fix as you go. Note every README step that is wrong or missing. If setup keeps fighting back (toolchain, ports, certificates, native deps), switch to `dev-env-setup`.

A repo is done when the app starts, one page or endpoint responds, and the test suite runs (passing, or with the known failures written down). At the end, offer a PR that fixes the README with what actually worked.

## Step 3: Conventions that matter

Take them from the "How we do X here" section of the repo map, or read 2-3 representative modules if there's no map. Keep to what a reviewer will flag:

- Branch naming, commit format, PR template, who reviews.
- Where business logic goes, and how data access is done.
- Auth and permission checks, and how queries are scoped to the user or tenant.
- Test style: runner, fixtures or factories, where shared helpers live.
- Migration rules (see `db-migrations`).
- Linters, formatters, pre-commit hooks. Install the hooks now.

Write it as a one-page `docs/onboarding.md` in the main repo, or update the existing one. Link to example files instead of copying code.

## Step 4: First-week task

Pick one, in this order:
1. An issue labelled `good first issue`, `onboarding` or similar (Atlassian MCP or Jira REST if configured, or `gh issue list --label "good first issue"`).
2. A small bug in a well-tested module.
3. Characterization tests for an untested area the team is about to change. Useful, low risk, and it teaches the code.

Say why that task, which files they'll touch, and the route; `ask-imogen` takes it from there. For unfamiliar code along the way, use `explain-code`.

## Step 5: Map

If no repo map existed, run `repo-map` now. If one exists, walk them through its Connections section; it's the fastest way to see how the system fits together.

## Rules

- Every setup step you hand over has been run, or is marked "not verified".
- Never ask for, print or commit secrets. Point to where they come from.
- Fix the docs as you go, so the next new dev hits fewer problems.
