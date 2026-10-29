---
name: pr-description
description: Turn the branch diff into a PR title and description — what changed and why, linked Jira ticket, blast radius, migration and deploy notes, and how it was tested — then open the PR with gh if asked. Use when "ready to open a PR", "write the PR description", or "open a PR for this".
---

# PR Description

A reviewer should understand what changed, why, what it could break, and how it was tested, in under a minute.

## Step 1: Gather

```bash
git fetch origin
git log --oneline origin/main..HEAD
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
```

(Use the repo's default branch if it isn't `main`.) Also find:

- The Jira key: from the branch name (`ABC-123-...`), commit messages, or ask.
- The ticket/PRD for the "why" and acceptance criteria.
- An `impact-analysis` report or `cross-repo-change` plan, if one exists, for blast radius and deploy order.
- The repo's PR template (`.github/pull_request_template.md`). If there is one, fill it instead of using the format below.

## Step 2: Write it

Title: `ABC-123: <what changed, imperative, under ~70 chars>`, or the repo's convention if `git log` shows a different one (e.g. conventional commits).

Body, short and plain:

```markdown
[ABC-123](https://<org>.atlassian.net/browse/ABC-123)

Adds a void action for invoices so org admins can cancel issued invoices without deleting them.

- `POST /api/invoices/{id}/void/` (org admins only)
- `Invoice.status` gets `void`; new `voided_at` / `voided_by`
- Void email moved from the post_save signal into `services.void_invoice()`

**Blast radius**
- web-app reads `status` and needs to handle `void` (web-app#88, deploy after this)
- reporting nightly export filters by status, updated here to include `void`

**Migration / deploy**
- 0042 adds two nullable columns to billing_invoice (~2M rows), metadata-only on Postgres
- Deploy backend before web-app#88

**Testing**
- New tests in billing/tests/test_void.py: admin can void, member 403, other org 404, can't void draft/void
- Ran the full suite locally; manually voided an invoice on local and checked the email
```

Rules for the content:
- Lead with the why in one or two sentences. Then the changes as a short list, only the ones a reviewer needs to know about.
- Blast radius and Migration/deploy sections only when there's something real to say. Drop them otherwise.
- Testing says what was actually run. Don't claim tests or manual checks that didn't happen.
- Call out anything the reviewer should look at closely ("the permission check in views.py:58 is the important bit").
- Write like a teammate, not a template. No filler, no emoji, no restating the diff line by line.
- Screenshots or example request/response for UI or API changes when they help.

## Step 3: Open it (only if asked)

Show the title and body first. On the dev's go-ahead:

```bash
git push -u origin HEAD
gh pr create --title "<title>" --body-file <tmpfile> --base main
```

Add `--draft` if the dev says it's not ready. Then, if the Atlassian MCP is connected and the dev agrees, comment the PR link on the Jira ticket.
