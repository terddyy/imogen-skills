# Imogen Skills

Agent skills for everyday dev work on any tech stack. They work in Claude Code, Codex and Cursor. You don't need to remember them: start with `ask-imogen`, describe what you're doing, and it reads your stack and picks the right skill (or chain of skills).

There are two kits in this repo:

| Kit | Where | Package | For |
| --- | --- | --- | --- |
| General | repo root | `imogen-skills` | Any stack: JS/TS, Python, Go, Rust, Ruby, PHP, Java, .NET... |
| Prosol | [`prosol/`](prosol/README.md) | `imogen-prosol` | Prosol's Django projects. All skills prefixed `prosol-` |

Prosol devs install only the Prosol kit. The kits share no skill names, so if someone does have both, nothing gets overwritten, and `ask-imogen` hands Django repos to `prosol-ask-imogen`.

## Install

One command, any OS (needs Node 18+). Re-run it to update.

```bash
npx imogen-skills@latest
```

No Node? Use the shell installers (same result, same update-by-rerun):

```bash
# macOS / Linux / Git Bash / WSL
curl -fsSL https://raw.githubusercontent.com/terddyy/imogen-skills/main/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/terddyy/imogen-skills/main/install.ps1 | iex
```

Prosol devs install `npx imogen-prosol@latest` instead: see [prosol/README.md](prosol/README.md).

Each installer checks which of Claude Code, Codex and Cursor you have and installs where each one looks:

| Tool | Folder |
| --- | --- |
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.agents/skills/` |
| Cursor | reads both of the above; `~/.cursor/skills/` if you only have Cursor |

Start a new session in your tool after installing.

Options:
- Choose the tools instead of auto-detecting: `npx imogen-skills@latest --tools codex,cursor` (shell installers: set `IMOGEN_TOOLS=codex,cursor`).
- Install into one folder only, e.g. inside a single project: `npx imogen-skills@latest --dir .agents/skills` (shell installers: `IMOGEN_SKILLS_DIR`).

If you have both Claude Code and Codex, Cursor may show each skill twice, because it reads both folders. The copies are the same.

### Upgrading from 1.x

`imogen-skills` 1.x was the Django kit. 2.0 is the general kit and overwrites the 18 skills whose names didn't change with stack-neutral versions. Delete the old `django-feature` and `django-migrations` folders by hand. Prosol devs should switch to the Prosol kit instead (see [prosol/README.md](prosol/README.md)).

### Companion skills

`ask-imogen` uses these for UI work when they're installed, and falls back to `ui-polish` otherwise. Each is maintained upstream, so install it from its own repo:

- [impeccable](https://github.com/pbakaus/impeccable) (Apache 2.0): design commands such as `critique`, `audit` and `polish`. Run `npx impeccable install` in the project.
- [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) (MIT): palettes, font pairings and design-system generation. Run `npx ui-ux-pro-max-cli init --ai claude --global`. Needs Python 3.

## Use

Just say what you're doing:

> client wants invoices to be voidable
> build ABC-123
> the dashboard is slow
> CI is red on my branch
> upgrade us to Next 16
> where do permissions live?

Or call a skill by name: `/ask-imogen` in Claude Code and Cursor, `$ask-imogen` in Codex. The same works for any skill (`/debug`, `$pr-description`, ...).

## The skills

| Group | Skill | What it does |
| --- | --- | --- |
| Front door | `ask-imogen` | Reads the stack, routes you to the right skill or chain, answers "where/how" from the repo map |
| Plan | `grill-plan` | Stress-tests a plan one question at a time until every branch is decided |
| | `prd-writer` | Rough request → spec with acceptance criteria, edge cases, affected repos |
| | `jira-tickets` | PRD → epics and tickets per repo with estimates, dependencies, blast radius |
| | `imogen-issue` | Idea → spec → GitHub issues a junior dev can pick up |
| | `impact-analysis` | Traces everything a change touches across all repos before work starts |
| | `adr` | Records architecture decisions and keeps the domain glossary |
| | `spike` | Throwaway prototype to answer one design question fast |
| Know the system | `repo-map` | Living map of every repo, what it owns, how they connect |
| | `onboarding` | Verified local setup per repo, conventions, first-week task |
| | `explain-code` | Walks a flow from entry point to side effects, with file:line citations |
| Build | `jira-build` | Implements a Jira ticket: description, comments and every image; compares the UI to mockups |
| | `imogen-fix-issues` | Fixes a GitHub issue end to end: test-first, reviewed, committed, PR |
| | `feature-build` | Builds a feature in vertical slices, mirroring the closest existing feature |
| | `test-first` | Red-green-refactor, one behavior at a time |
| | `safe-change` | Expand-and-contract steps so edits don't break existing callers |
| | `db-migrations` | Safe migrations for any tool: no table locks, reversible, batched backfills |
| | `api-design` | Designs or changes an API to match the repo's conventions, contract first |
| | `cross-repo-change` | Orders changes, PRs and deploys when a feature spans repos |
| | `overnight-task-runner` | Plans and runs a large task end to end while you're away |
| Protect | `characterization-tests` | Locks current behavior before touching untested code |
| | `contract-tests` | Guards API responses and events shared between repos |
| | `test-writer` | Unit and integration tests in the repo's own style |
| | `e2e-tests` | Browser and API journeys with stable selectors and no sleeps |
| | `verify-done` | Proves the work: build, types, lint, tests, and the real feature, with evidence |
| Debug and quality | `debug` | Repro → hypotheses → root cause → fix → regression test |
| | `security-audit` | Auth, tenant scoping, injection, XSS/CSRF/SSRF, secrets, dependency CVEs |
| | `code-quality` | Pre-PR review: house style, hidden coupling, test gaps, light security pass |
| | `refactor-plan` | Turns a refactor into tiny commits that each keep tests green |
| | `improve-architecture` | Finds shallow modules and leaky seams; designs the fix interface first |
| | `dependency-upgrade` | Upgrades a dependency or framework one major at a time |
| Optimize | `perf-audit` | Backend and frontend: N+1s, indexes, payloads, bundles, Web Vitals; outputs tickets |
| | `query-optimizer` | Rewrites slow DB access for whatever ORM or SQL the repo uses |
| | `caching-strategy` | What to cache, at which layer, keys, TTLs, invalidation |
| UI | `ui-polish` | Spacing, hierarchy, type, contrast and states, using the repo's design system |
| | `accessibility-audit` | WCAG 2.2 AA checks with file:line fixes |
| Docs and comms | `docs-writer` | README, API docs and guides, with every command verified |
| | `commit-message` | Conventional commits in the repo's style; splits mixed diffs |
| | `pr-description` | Diff → short PR body with ticket, blast radius, testing notes |
| | `session-handoff` | Compacts the session into a doc another dev or agent can pick up |
| DevOps and ship | `ci-fix` | Diagnoses a red pipeline and fixes the root cause |
| | `dev-env-setup` | One-command local setup: `.env.example`, Docker/devcontainer, seeds, pre-commit |
| | `deploy-checklist` | Pre- and post-deploy checks, rollback plan, what to watch |
| | `regression-postmortem` | Finds why something broke, turns it into a test; drafts release notes |

## First time on a project

Run `repo-map` once from the folder that holds all the project's repos. Many skills read from it, and `ask-imogen` answers "where does X live" from it instantly.

Jira: `jira-tickets` and `perf-audit` create tickets directly if the Atlassian MCP is connected. Without it they write a markdown file and a CSV you can import. `jira-build` reads tickets through the Atlassian MCP, or the Jira REST API if `JIRA_URL`, `JIRA_EMAIL` and `JIRA_API_TOKEN` are set. Without either, it asks you to paste the ticket.

## Uninstall

Delete the skill folders listed above from `~/.claude/skills/`, `~/.agents/skills/` and `~/.cursor/skills/` (whichever exist).

## Releasing (maintainers)

The npm packages bundle the skills, so `npx` users only get changes after a publish. After merging to main:

```bash
npm version patch --no-git-tag-version && npm publish                 # general kit, from the repo root
cd prosol && npm version patch --no-git-tag-version && npm publish    # Prosol kit
```

Then commit the bumped `package.json`. The shell installers pull straight from GitHub main and don't need a publish.
