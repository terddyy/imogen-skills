# Imogen AI Consulting Skills

19 Claude Code skills for working on client Django projects. You don't need to remember them: start with `ask-imogen`, describe what you're doing, and it picks the right skill (or chain of skills).

## Install

One command. Re-run the same command to update.

macOS / Linux / Git Bash / WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/terddyy/imogen-skills/main/ai-consulting-1/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/terddyy/imogen-skills/main/ai-consulting-1/install.ps1 | iex
```

Skills go to `~/.claude/skills/`. Start a new Claude Code session after installing. To install into a single project instead, set `CLAUDE_SKILLS_DIR=.claude/skills` before running.

## Use

Just say what you're doing in Claude Code:

> client wants invoices to be voidable
> I need to build ABC-123
> the invoice list page is slow
> something broke after my last deploy
> where do permissions live?

Or call `/ask-imogen` directly, or any skill by name (`/perf-audit`, `/pr-description`, ...).

## The skills

| Group | Skill | What it does |
| --- | --- | --- |
| Front door | `ask-imogen` | Routes you to the right skill or chain; answers "where/how" from the repo map |
| Plan | `prd-writer` | Rough request → spec with acceptance criteria, edge cases, affected repos |
| | `jira-tickets` | PRD → epics and tickets per repo with estimates, dependencies, blast radius |
| | `impact-analysis` | Traces everything a change touches across all repos before work starts |
| Know the system | `repo-map` | Living map of every repo, what it owns, how they connect |
| | `onboarding` | Verified local setup per repo, conventions, first-week task |
| Build | `django-feature` | Model, serializer, view, URLs, permissions, tests in house style |
| | `safe-change` | Expand-and-contract steps so edits don't break existing callers |
| | `django-migrations` | Safe migrations: no table locks, reversible, batched backfills |
| | `cross-repo-change` | Orders changes, PRs and deploys when a feature spans repos |
| Protect | `characterization-tests` | Locks current behavior before touching untested code |
| | `contract-tests` | Guards API responses shared between repos |
| | `test-writer` | pytest-django tests for new and existing code |
| Optimize | `perf-audit` | Finds N+1s, missing indexes, heavy serializers; outputs Jira tickets |
| | `query-optimizer` | Rewrites slow ORM code and adds query-count guards |
| | `caching-strategy` | What to cache, keys, invalidation |
| Review and ship | `code-quality` | Style, hidden coupling, Django security checks |
| | `pr-description` | Diff → PR summary, linked ticket, blast radius, testing notes |
| | `regression-postmortem` | Finds why something broke, turns it into a test; drafts release notes |

## Common routes

| You say... | Route |
| --- | --- |
| "Client wants a new feature" | prd-writer → jira-tickets → impact-analysis |
| "I need to build this ticket" | impact-analysis → django-feature → test-writer → pr-description |
| "I need to change this model / endpoint" | impact-analysis → characterization-tests → safe-change → django-migrations |
| "This touches the other repo" | impact-analysis → cross-repo-change → contract-tests |
| "This page is slow" | perf-audit → query-optimizer → caching-strategy |
| "Something broke after my change" | regression-postmortem → characterization-tests |
| "I'm scared to touch this code" | characterization-tests → safe-change |
| "Where does X live? How do we do Y?" | answered from repo-map |
| "I'm new here" | onboarding → repo-map |
| "Ready to open a PR" | code-quality → pr-description |

## First time on a client project

Run `repo-map` once from the folder that holds all the client's repos. Most of the other skills read from it, and `ask-imogen` answers "where does X live" from it instantly.

Jira: `jira-tickets` and `perf-audit` can create tickets directly if you have the Atlassian MCP connected. Without it, they write a markdown file and a CSV you can import into Jira.

## Uninstall

Delete the 19 skill folders listed above from `~/.claude/skills/`.
