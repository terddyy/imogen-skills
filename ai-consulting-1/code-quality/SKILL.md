---
name: code-quality
description: Review a Django branch before the PR — house style, hidden coupling (signals, fat models, business logic in serializers/views), test gaps, and Django/DRF security checks (permissions, tenant scoping, mass assignment, raw SQL, unsafe settings). Use when "ready to open a PR", "review my changes", "check this before I push", or as a reviewer on someone else's branch.
---

# Code Quality

Review the diff the way a senior reviewer on this client would, then fix what's real. Findings must be specific (file:line + why + fix), and ranked so the dev fixes the important ones first.

## Step 1: Get the diff and the context

```bash
git fetch origin
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
```

Use the repo's default branch if it isn't `main`. Also read: the ticket/PRD (to check scope), the repo map's "How we do X here" section, and any `CONTRIBUTING.md` / `CODING_STANDARDS.md`. A documented house rule always beats the generic advice below.

## Step 2: Run the tools first

Run whatever the project has configured, so you don't spend review time on things a linter catches: `pre-commit run --from-ref origin/main --to-ref HEAD`, or ruff/black/isort/flake8/mypy directly, plus:

```bash
python manage.py check
python manage.py makemigrations --check --dry-run
pytest <changed apps>
```

Report tool failures first.

## Step 3: Review in three passes

Keep the passes separate in the report.

**Pass 1: Security (Django/DRF)**
- Every new view has explicit `permission_classes`; no `AllowAny` unless it's meant to be public.
- Querysets scoped to the requesting user/org in `get_queryset`. `Model.objects.get(pk=...)` with an id from the request and no ownership check = IDOR.
- Serializers that accept input list `fields` explicitly; no `"__all__"`; server-owned fields (`org`, `owner`, `is_staff`, `status`, prices) are `read_only` and set in the view/service.
- Raw SQL / `.extra()` / `RawSQL` parameterized, never built with f-strings or `%`.
- `mark_safe`, `|safe`, `format_html` misuse with user content; `csrf_exempt` on session-authenticated views.
- File uploads: size, extension and content-type checked; stored outside web root; filenames not trusted.
- Secrets or credentials in code, settings, fixtures or tests. Settings changes that weaken security (`DEBUG`, `ALLOWED_HOSTS = ["*"]`, CORS `*` with credentials).
- Outbound requests have timeouts; URLs built from user input are validated (SSRF).
- `pickle`, `yaml.load` without SafeLoader, `eval`/`exec` on anything external.
- Sensitive data (tokens, passwords, PII) not logged.

**Pass 2: Design and hidden coupling**
- **Signals** that carry business logic: a `post_save` receiver that sends emails or updates other models hides side effects from anyone reading the calling code, and skips on `bulk_*`/`update()`. Prefer an explicit call in the service.
- **Logic in serializers**: `create()`/`update()`/`validate()` doing multi-model writes, external calls, or business rules. Move to the service layer (or wherever the house puts it).
- **Fat views**: ORM-heavy logic, branching on business rules in the view.
- **Fat models / `save()` overrides** with side effects (emails, API calls, other-model writes).
- Side effects outside `transaction.on_commit` (task queued before the row is committed → task can't find it).
- Cross-app imports that create cycles, or reaching into another app's internals instead of its service API.
- Shotgun surgery: the same rule duplicated in several places; magic strings for statuses instead of the model's choices.
- N+1s introduced (quick check: new serializer fields touching relations, loops over querysets).
- Scope creep vs the ticket, and acceptance criteria not met.

**Pass 3: Tests**
- Each acceptance criterion has a test. Permission and cross-tenant cases covered.
- Tests assert behavior, not implementation (no mocking the code under test).
- Migrations reviewed per `django-migrations` if any.

## Step 4: Report, then fix

```
Security
  [Must fix] billing/views.py:58 InvoiceVoidView fetches Invoice.objects.get(pk=pk) with no org check → any user can void any org's invoice. Use self.get_queryset().get(pk=pk) (scoped) or get_object().
Design
  [Should fix] billing/signals.py:12 post_save sends the void email; move to services.void_invoice() inside on_commit.
Tests
  [Should fix] no test for member role → add test_member_cannot_void.
Nits
  [Optional] ...
```

Levels: **Must fix** (security, data loss, broken behavior, failing checks), **Should fix** (design/test gaps a reviewer will flag), **Optional**. Ask the dev which to fix, fix them, re-run the tools and tests, then suggest `pr-description`.

## Rules

- No finding without a file:line and a concrete fix.
- Don't flag style the formatter owns, or pre-existing issues outside the diff (mention those separately as "noticed, not in scope").
- Don't approve something you couldn't run; say what you couldn't verify.
