---
name: django-feature
description: Scaffold a Django/DRF feature in the project's house style — model, migration, serializer, view, URLs, permissions, admin and tests — copying the patterns the repo already uses. Use when building a ticket that adds a new resource or endpoint, or when someone says "scaffold", "add an endpoint for", or "build this ticket".
---

# Django Feature

Build the feature the way this codebase already builds features. The biggest review complaint on client projects isn't bugs, it's "we don't do it like that here". So: copy house style first, invent nothing.

## Step 1: Learn the house style (don't skip)

Read the "How we do X here" section of the repo map if there is one. Then open the closest existing feature to what you're building (same app if possible, a similar CRUD resource otherwise) and note:

- Views: `ModelViewSet` / `GenericAPIView` / `APIView` / function views? Router or explicit `path()`?
- Where logic lives: `services.py` / `selectors.py`, model methods, or serializers?
- Permissions: which classes, and how `get_queryset` scopes by user/org/tenant.
- Serializers: separate read/write serializers? `fields = [...]` explicitly listed (should be)?
- Pagination, filtering (`django-filter`?), ordering defaults.
- Model conventions: base model (`TimeStampedModel`, UUID pk?), `related_name` style, `Meta.ordering`, `__str__`.
- Admin registration pattern.
- Tests: location, pytest-django vs `TestCase`, factories (`factory_boy`?), API client fixtures in `conftest.py`.
- URL and naming: kebab vs snake case in paths, `basename`s.

Tell the dev in 4-6 bullets which existing feature you're mirroring and the patterns you'll copy. If two patterns coexist (legacy + new), ask which one is current.

## Step 2: Plan the files

List every file you'll create or touch before writing. Typical set:

```
billing/models.py            + CreditNote
billing/migrations/00xx_...  (generated)
billing/services.py          + issue_credit_note()
billing/serializers.py       + CreditNoteSerializer
billing/views.py             + CreditNoteViewSet
billing/urls.py              register route
billing/admin.py             register model
billing/tests/test_credit_notes.py
```

If the model or endpoint is shared with other repos (check the repo map or the `impact-analysis` report), stop and route through `safe-change` / `cross-repo-change` instead of changing it directly.

## Step 3: Build, test-first per slice

Work one slice at a time, each ending green:

1. **Model + migration.** `makemigrations`, then read the migration and the SQL (`sqlmigrate`) against `django-migrations` rules. Explicit `on_delete`, `related_name`, indexes for fields you'll filter/order by.
2. **Write path.** Failing API test for create (happy path + permission denied + validation error) → serializer + service + view → green.
3. **Read path.** Failing tests for list/retrieve including "user can't see another org's rows" → view `get_queryset` scoping → green. Add a query-count guard on the list endpoint (`django_assert_max_num_queries`) and fix N+1s with `select_related`/`prefetch_related` now, not later.
4. **Update/delete** if in scope, same pattern.
5. **Admin, URLs, docs** (OpenAPI annotations if the project uses drf-spectacular).

Use `test-writer` conventions for the tests.

## Step 4: Check before handing off

- `python manage.py makemigrations --check --dry-run` (no missing migrations)
- `python manage.py check`
- The project's linters/formatters (ruff, black, isort, flake8, mypy: whatever is configured)
- Full test suite for the app, then the whole suite if it's fast

Then suggest `code-quality` → `pr-description`.

## Rules

- Never `fields = "__all__"` on a serializer that accepts input. List fields; mark server-set ones `read_only_fields`.
- Every queryset in a view is scoped to what the requesting user may see. No unscoped `Model.objects.all()` in an API view.
- Explicit `permission_classes` on every new view, even if it matches the default.
- No business logic in views. Follow the house pattern for where it goes; if there's none, use a `services.py` function.
- Side effects that touch the outside world (emails, tasks, webhooks) go in `transaction.on_commit`.
