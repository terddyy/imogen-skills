---
name: security-audit
description: Audit a branch, a feature, or a whole repo for security problems on any stack: authn/authz and tenant scoping, input validation, injection (SQL, command, template), XSS, CSRF, SSRF, secrets in code or logs, vulnerable dependencies, and unsafe config, headers or CORS. Produces findings ranked by severity, each with file:line, impact and a fix. Use when "is this secure", "security review", "before we go live", "audit this endpoint", "check for vulnerabilities", or when code-quality flags something that needs a deeper look.
---

# Security Audit

Find real, exploitable problems and show how to fix them. Every finding names the file, the line, how it can be abused, and the fix.

## Step 0: Read the stack

Detect the language and framework from the manifests (package.json + lockfile, pyproject.toml/requirements*.txt, go.mod, Cargo.toml, Gemfile, composer.json, pom.xml/build.gradle). Find how this repo already does auth, permissions, validation and tenant scoping (middleware, decorators, guards, policies, base classes) so you can spot code that skips them. Read the repo map if present (`../repo-map.md` or `docs/repo-map.md`) and verify it against code.

## Step 1: Scope

- Branch: `git diff origin/main...HEAD` (use the repo's default branch).
- Feature or endpoint: trace it from route to data store and back.
- Whole repo: list the entry points first (routes, controllers, handlers, queue consumers, webhooks, CLI commands, cron jobs) and go through them by exposure: public, then authenticated, then internal.

## Step 2: Run the scanners

Run what applies, and report the output with severities:

```bash
npm audit --omit=dev        # or pnpm audit / yarn npm audit
pip-audit                   # Python
govulncheck ./...           # Go
cargo audit                 # Rust
bundle audit                # Ruby
gitleaks detect --no-banner # secrets, if installed
```

Also run any SAST already in the repo or CI (semgrep, bandit, gosec, brakeman, CodeQL). For a dependency CVE, check whether the vulnerable function is actually reachable from this code before calling it Critical.

## Step 3: Review by category

- **Authn:** every non-public route goes through the auth layer. Token/JWT checks pin the algorithm and verify signature, expiry and audience. Password reset and session tokens are random, single-use and expire.
- **Authz and tenant scoping:** each read and write checks that the caller may touch that record. An id from the request used in a lookup with no owner/org filter is an IDOR. Role checks happen on the server, not only in the UI.
- **Input validation:** request bodies, params, headers and files go through a schema (zod, pydantic, the framework's validators). Server-owned fields (`role`, `orgId`, `price`, `isAdmin`) can't be set by the client (mass assignment). Size limits on bodies and uploads; upload type checked by content, not just extension.
- **Injection:** SQL built with string concatenation or interpolation instead of parameters; shell calls with user input (`exec`, `subprocess(shell=True)`, `child_process.exec`); template rendering of user strings; `eval`, unsafe deserialization (`pickle`, `yaml.load`, Java serialization); path traversal in file paths.
- **XSS:** raw HTML sinks (`dangerouslySetInnerHTML`, `v-html`, `innerHTML`, `|safe`, `html_safe`) fed user content without a sanitizer such as DOMPurify.
- **CSRF:** cookie-authenticated state-changing routes have CSRF protection or `SameSite` cookies; no blanket CSRF exemptions.
- **SSRF:** outbound requests to URLs from user input are checked against an allowlist; internal and metadata addresses (`169.254.169.254`, `localhost`, private ranges) blocked; timeouts set.
- **Secrets:** no keys, tokens or passwords in code, config, fixtures, tests, or git history (`git log -p -S "AKIA"`). Logs and error responses don't include tokens, passwords or PII. Stack traces aren't returned to clients.
- **Config and headers:** debug mode off in prod config; CORS uses explicit origins (never `*` with credentials); cookies `HttpOnly`, `Secure`, `SameSite`; CSP, HSTS, `X-Content-Type-Options` set; rate limits on login, signup, reset and other expensive endpoints.

## Step 4: Report

Rank by severity (Critical, High, Medium, Low), then by how easy the exploit is:

```
[Critical] IDOR on invoice void
Where: src/routes/invoices.ts:58  findById(req.params.id) with no org filter
Exploit: any logged-in user can void another org's invoice by changing the id
Fix: scope the lookup with orgId from the session (same as invoices.ts:22); add a cross-org test
```

Then a short list of what you checked and found clean, and what you couldn't verify (no access to prod config, scanner not installed).

## Rules

- No finding without file:line, an abuse scenario, and a concrete fix. "Could be risky" isn't a finding.
- Never run exploits against shared or production environments. Prove it with a local test instead.
- Never print a secret you find. Give its location and say it must be rotated, not just deleted, because git history keeps it.
- Fix only after the dev picks which findings to fix. Each fix gets a test that would have caught it.

Next: `code-quality` for the rest of the review, `dependency-upgrade` for vulnerable packages, `jira-tickets` for findings that won't be fixed now.
