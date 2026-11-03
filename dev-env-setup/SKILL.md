---
name: dev-env-setup
description: Make a repo runnable from a clean checkout - a .env.example with no real secrets, Docker Compose or a devcontainer when the repo already uses them, seed data, a one-command setup (Makefile target or package scripts), and pre-commit hooks for the lint/format/typecheck tools the repo already has - then prove it with a fresh setup. Use when "it only runs on my machine", "new dev can't get it running", "set up the project locally", "add a .env.example", "add pre-commit hooks", or when onboarding takes a day instead of an hour.
---

# Dev Env Setup

Goal: a new dev runs one or two commands after cloning and has the app running with data. Build on what the repo already uses; don't introduce a new toolchain.

## Step 0: Read the stack

Read manifests (`package.json` + lockfile, `pyproject.toml`/`requirements*.txt`, `go.mod`, `Gemfile`, `composer.json`, `pom.xml`/`build.gradle`), version files (`.nvmrc`, `.python-version`, `.tool-versions`, `rust-toolchain.toml`), and anything existing: `docker-compose.yml`, `.devcontainer/`, `Makefile`, `justfile`, `scripts/`, README setup section, CI config (CI is often the most accurate record of what the app needs). Note which services it depends on: database, cache, queue, object storage, email.

## Step 1: Find the gaps

Try the documented setup in a clean place (a fresh clone in a temp folder or a new worktree). Write down every step that fails or needs tribal knowledge: missing env var, unlisted service, manual DB creation, a migration that needs a flag, a binary that must be installed by hand.

## Step 2: Env vars

1. Collect every var the code reads: grep for `process.env.`, `import.meta.env.`, `os.environ`/`os.getenv`, `ENV[`, `os.Getenv`, plus the framework's settings files and CI config.
2. Write `.env.example` with every var, grouped and commented, with safe local defaults (`DATABASE_URL=postgres://app:app@localhost:5432/app_dev`) and obvious placeholders for third-party keys (`STRIPE_SECRET_KEY=sk_test_replace_me`).
3. Confirm `.env` and `.env.*.local` are in `.gitignore`. If a real `.env` is committed, tell the dev; the secrets in it need rotating, not just deleting.
4. If the app fails cryptically on a missing var, add a startup check using the repo's config/validation pattern (zod, pydantic-settings, envconfig) if it has one.

## Step 3: Services

- If the repo uses Docker Compose, add missing services there with pinned image versions matching production, named volumes, and healthchecks. Expose the ports `.env.example` points at.
- If it uses a devcontainer, keep `devcontainer.json` in step: same tool versions, `postCreateCommand` running the setup.
- If it uses neither, don't force Docker in. Document the native install with exact versions instead, and ask the dev if they want Compose added.

## Step 4: Seed data

Use the repo's seeding mechanism (Prisma `seed`, `manage.py loaddata` or a management command, `rails db:seed`, a `scripts/seed` file). Seed enough to click through the main flows: one admin, one normal user, a few records per main entity. Make it idempotent (upsert, or reset-then-seed). Print the login credentials at the end; local-only values, never real ones.

## Step 5: One command

Add a single entry point in the style the repo already uses:

```make
setup:      ## first-time setup
	cp -n .env.example .env || true
	docker compose up -d --wait
	npm ci
	npm run db:migrate && npm run db:seed
dev:        ## run the app
	npm run dev
```

Or the equivalent `package.json` scripts (`"setup": "..."`), `just setup`, or `bin/setup`. Make it safe to run twice.

## Step 6: Pre-commit hooks

Wire hooks to the tools already configured, using the repo's ecosystem: `husky` + `lint-staged` for JS/TS, `pre-commit` (`.pre-commit-config.yaml`) for Python and mixed repos, `lefthook` if it's already there. Run formatters and linters on staged files only; keep typecheck fast or move it to pre-push. Don't add a linter the repo doesn't use.

## Step 7: Verify from clean

Delete the temp clone, clone again, follow only the README, and time it. The app must start, log in with the seeded user, and pass the test suite. Update the README setup section to match exactly what you ran.

## Rules

- No real secrets anywhere in the repo: not in `.env.example`, Compose files, seeds or README.
- Pin versions (images, runtimes) to what production and CI use.
- Don't change production config, deploy files or CI behavior as part of local setup.
- Every step you add must run on Windows (WSL or Git Bash), macOS and Linux, or say which it doesn't.

Next: `onboarding` for the new dev's walkthrough, `docs-writer` for the README, `ci-fix` if CI and local disagree.
