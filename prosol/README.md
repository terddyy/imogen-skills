# Imogen Prosol Skills

20 agent skills for working on Prosol's Django projects. Every skill is prefixed `prosol-`. Works in Claude Code, Codex and Cursor. You don't need to remember them: start with `prosol-ask-imogen`, describe what you're doing, and it picks the right skill (or chain of skills).

## Install

One command, any OS. Re-run it to update.

```bash
# macOS / Linux / Git Bash / WSL
curl -fsSL https://raw.githubusercontent.com/terddyy/imogen-skills/main/prosol/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/terddyy/imogen-skills/main/prosol/install.ps1 | iex
```

Each installer checks which of Claude Code, Codex and Cursor you have and installs where each one looks:

| Tool | Folder |
| --- | --- |
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.agents/skills/` |
| Cursor | reads both of the above; `~/.cursor/skills/` if you only have Cursor |

Start a new session in your tool after installing.

The npm package (`npx imogen-prosol@latest`) isn't published yet; use the commands above for now.

Options:
- Choose the tools instead of auto-detecting: set `IMOGEN_TOOLS=codex,cursor` (npm installer, once published: `--tools codex,cursor`).
- Install into one folder only, e.g. inside a single project: set `IMOGEN_SKILLS_DIR=.agents/skills` (npm installer: `--dir`). `.agents/skills` works for Codex and Cursor, `.claude/skills` for Claude Code and Cursor.

If you have both Claude Code and Codex, Cursor may show each skill twice, because it reads both folders. The copies are the same, so it doesn't matter which one Cursor picks.

## Use

Just say what you're doing in your agent:

> client wants invoices to be voidable
> I need to build ABC-123
> the invoice list page is slow
> something broke after my last deploy
> where do permissions live?

Or call a skill by name: `/prosol-ask-imogen` in Claude Code and Cursor, `$prosol-ask-imogen` in Codex. The same works for any skill (`/prosol-perf-audit`, `$prosol-pr-description`, ...).
## The skills

| Group | Skill | What it does |
| --- | --- | --- |
| Front door | `prosol-ask-imogen` | Routes you to the right skill or chain; answers "where/how" from the repo map |
| Plan | `prosol-prd-writer` | Rough request → spec with acceptance criteria, edge cases, affected repos |
| | `prosol-jira-tickets` | PRD → epics and tickets per repo with estimates, dependencies, blast radius |
| | `prosol-jira-build` | Implements a Jira ticket: pulls description, comments and every image, reuses existing code, checks what it affects, compares screenshots to the mockups until they match |
| | `prosol-impact-analysis` | Traces everything a change touches across all repos before work starts |
| Know the system | `prosol-repo-map` | Living map of every repo, what it owns, how they connect |
| | `prosol-onboarding` | Verified local setup per repo, conventions, first-week task |
| Build | `prosol-django-feature` | Model, serializer, view, URLs, permissions, tests in house style |
| | `prosol-safe-change` | Expand-and-contract steps so edits don't break existing callers |
| | `prosol-django-migrations` | Safe migrations: no table locks, reversible, batched backfills |
| | `prosol-cross-repo-change` | Orders changes, PRs and deploys when a feature spans repos |
| Protect | `prosol-characterization-tests` | Locks current behavior before touching untested code |
| | `prosol-contract-tests` | Guards API responses shared between repos |
| | `prosol-test-writer` | pytest-django tests for new and existing code |
| Optimize | `prosol-perf-audit` | Finds N+1s, missing indexes, heavy serializers; outputs Jira tickets |
| | `prosol-query-optimizer` | Rewrites slow ORM code and adds query-count guards |
| | `prosol-caching-strategy` | What to cache, keys, invalidation |
| Review and ship | `prosol-code-quality` | Style, hidden coupling, Django security checks |
| | `prosol-pr-description` | Diff → PR summary, linked ticket, blast radius, testing notes |
| | `prosol-regression-postmortem` | Finds why something broke, turns it into a test; drafts release notes |

## Common routes

| You say... | Route |
| --- | --- |
| "Client wants a new feature" | prosol-prd-writer → prosol-jira-tickets → prosol-impact-analysis |
| "I need to build this ticket" / "build ABC-123" | prosol-jira-build → prosol-code-quality → prosol-pr-description |
| "I need to change this model / endpoint" | prosol-impact-analysis → prosol-characterization-tests → prosol-safe-change → prosol-django-migrations |
| "This touches the other repo" | prosol-impact-analysis → prosol-cross-repo-change → prosol-contract-tests |
| "This page is slow" | prosol-perf-audit → prosol-query-optimizer → prosol-caching-strategy |
| "Something broke after my change" | prosol-regression-postmortem → prosol-characterization-tests |
| "I'm scared to touch this code" | prosol-characterization-tests → prosol-safe-change |
| "Where does X live? How do we do Y?" | answered from prosol-repo-map |
| "I'm new here" | prosol-onboarding → prosol-repo-map |
| "Ready to open a PR" | prosol-code-quality → prosol-pr-description |

## First time on a client project

Run `prosol-repo-map` once from the folder that holds all the client's repos. Most of the other skills read from it, and `prosol-ask-imogen` answers "where does X live" from it instantly.

Jira: `prosol-jira-tickets` and `prosol-perf-audit` can create tickets directly if you have the Atlassian MCP connected. Without it, they write a markdown file and a CSV you can import into Jira. `prosol-jira-build` reads tickets and downloads their images through the Atlassian MCP, or through the Jira REST API if `JIRA_URL`, `JIRA_EMAIL` and `JIRA_API_TOKEN` are set. Without either, it asks you to paste the ticket and images.

## Upgrading from the old kit

The old `imogen-skills` package installed these skills without the `prosol-` prefix. After installing this one, delete the 20 old unprefixed folders (`ask-imogen`, `django-feature`, `test-writer`, ...) from your skills folders, so only the `prosol-*` versions are left. Don't install `imogen-skills` alongside it; this kit is all you need.

## Uninstall

Delete the 20 `prosol-*` skill folders from `~/.claude/skills/`, `~/.agents/skills/` and `~/.cursor/skills/` (whichever exist).

## Releasing a new version (maintainers)

The npm package bundles the skills, so `npx` users only get changes after a publish. After merging skill changes to main:

```bash
cd prosol
npm version patch --no-git-tag-version
npm publish
```

Then commit the bumped `package.json`.

The shell installers pull straight from GitHub main and don't need a publish.
