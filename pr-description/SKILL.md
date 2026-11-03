---
name: pr-description
description: Turn the branch diff into a PR title and a short, human-sounding description that covers what changed and why, the linked ticket, blast radius, deploy notes, and how it was tested. Opens the PR with gh (or glab) when asked. Use when someone says "ready to open a PR", "write the PR description", "open a PR for this", or "what should the PR say".
---

# PR Description

A reviewer should get what changed, why, what it could break, and how it was tested in under a minute. It should read like a teammate wrote it.

## Step 1: Gather

```bash
git fetch origin
git log --oneline origin/main..HEAD
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
```

Use the repo's default branch if it is not `main` (`git remote show origin | grep HEAD`). Also find:

- The ticket key: branch name (`ABC-123-...`), commit messages, or ask. Pull the ticket for the "why" and the acceptance criteria (Atlassian MCP, or REST with JIRA_URL / JIRA_EMAIL / JIRA_API_TOKEN; never print the token). GitHub issues: `gh issue view <n>`.
- An `impact-analysis` report or `cross-repo-change` plan, if one exists, for blast radius and deploy order.
- Evidence from `verify-done`, if it was run, for the testing notes.
- The repo's PR template (`.github/pull_request_template.md`, `.gitlab/merge_request_templates/`). If there is one, fill it instead of the shape below.

## Step 2: Write it

Title: follow what `git log` and merged PRs show (`gh pr list --state merged -L 10`), e.g. `ABC-123: Add void action for invoices` or `feat(billing): add invoice void action`. Imperative, under about 70 characters.

Body, a few lines:

```markdown
ABC-123

Lets org admins void an issued invoice instead of deleting it, so the audit trail stays intact.

- New `POST /api/invoices/:id/void`, admins only
- `status` gains `void`; adds `voided_at` and `voided_by` columns
- The void email now goes out from `voidInvoice()` instead of the model hook

web-app reads `status` and needs to handle `void` (web-app#88, deploy after this one). Migration adds two nullable columns, no backfill.

Tested: new tests in `invoices.void.test.ts` (admin ok, member 403, other org 404, can't void a draft), full suite green, voided one locally and checked the email in Mailpit.
```

- Lead with the why in one or two sentences, then only the changes a reviewer needs to know about.
- Blast radius, migration, and deploy order only when there is something real to say. Drop them otherwise.
- Testing says what was actually run. Never claim a test or manual check that did not happen.
- Point at the part that needs a close look ("the permission check in `routes/invoices.ts:58` is the important bit").
- Add a screenshot or an example request/response for UI or API changes when it helps.
- No headings, bold labels, emoji, or "Summary / Changes / Testing" template on a small PR. No filler like "This PR aims to". No restating the diff line by line. No AI or generated-by mentions, no co-author lines.

## Step 3: Open it (only if asked)

Show the title and body first. On the dev's go-ahead, write the body to a temp file and:

```bash
git push -u origin HEAD
gh pr create --title "<title>" --body-file <tmpfile> --base main      # add --draft if not ready
# GitLab: glab mr create --title "<title>" --description "$(cat <tmpfile>)"
```

Then, if the dev agrees, comment the PR link on the ticket.

## Rules

- Never push or open the PR without the dev's go-ahead.
- Never invent testing, ticket keys, or reviewers.
- Keep it short. If the body needs more than about 15 lines, the PR is probably too big; say so.

Next: `code-quality` for a review pass, `ci-fix` if checks fail after opening.
