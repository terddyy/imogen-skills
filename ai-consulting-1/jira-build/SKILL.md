---
name: jira-build
description: Implement a Jira ticket end to end, with UI that matches the ticket's mockups as close to pixel-perfect as possible. Pulls the full ticket (description, comments, every attached image, Figma links), turns the images into a measured spec, reuses existing components and helpers, checks what the change affects, then builds and compares screenshots against the mockups until they match. Use when someone says "build ABC-123", "implement this ticket", "do this Jira", or pastes a Jira key or link.
---

# Jira Build

The ticket is the spec, and the images in the ticket are the source of truth for the UI. "Close enough" means a designer looking at both side by side can't find a difference. Guessing a layout from the description text alone is the failure this skill exists to prevent.

## Step 1: Pull the whole ticket

Get all of it, not just the summary:

- Summary, description, acceptance criteria, issue type, labels.
- **Every attachment.** Download each image locally and open it. Inline images in the description are attachments too.
- Comments, newest first. A later comment from the designer or PO overrides the description. Note which comment changed what.
- Linked issues, subtasks, parent epic (the epic often holds the design link).
- Design links in the description or comments: Figma, Zeplin, Loom, Google Drive.

How to fetch, in order of preference:

1. **Atlassian MCP.** Get the issue (`getJiraIssue` / `jira_get_issue`), then download attachments (`jira_download_attachments` or the server's equivalent).
2. **REST API**, if `JIRA_URL`, `JIRA_EMAIL` and `JIRA_API_TOKEN` are set in the environment (never ask the dev to paste a token into chat):
   ```bash
   curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
     "$JIRA_URL/rest/api/3/issue/ABC-123?fields=summary,description,attachment,comment,issuelinks,subtasks,parent&expand=renderedFields"
   # for each attachment id in fields.attachment:
   curl -sL -u "$JIRA_EMAIL:$JIRA_API_TOKEN" "$JIRA_URL/rest/api/3/attachment/content/<id>" -o "<dir>/<filename>"
   ```
   `renderedFields.description` is HTML. Inline images point at attachments by filename, so you can tell which image goes with which paragraph.
3. **Neither available:** ask the dev to paste or drop the ticket text and every image into the chat or a folder.

Save images outside the repo (a temp or scratch folder), or in a folder listed in `.git/info/exclude`. They're client material, so don't commit them unless asked.

**If the ticket has UI work and you can't see the images, stop.** Don't build UI from the text. Ask for the images.

If there's a Figma link and a Figma MCP is connected, pull the frame's design context and screenshot. Exact values from Figma beat values estimated from a PNG.

### Sort the images before using them

Not every image is the design to build. Label each one, using the ticket text, filename, comment it was posted in, and what it shows:

| Label | Looks like | How to use it |
| --- | --- | --- |
| **Target** | Clean design, Figma/Zeplin export, "should look like", "new design" | Spec it in Step 2 and match it in Step 7 |
| **Current** | Screenshot of the live app, often on a bug ticket: "currently", "this is broken", browser chrome, real data | Shows what's wrong and where. Never copy it. Reproduce it before fixing, and confirm it's gone after |
| **Annotated** | Screenshot with arrows, circles, boxes, sticky notes, strike-throughs, handwriting | List each mark as a separate requested change ("make this button blue", "remove this column"). The marks themselves are not part of the UI |
| **Context** | Flow diagram, error message, console or network log, data sample, competitor reference | Read it for behavior and requirements. Not a pixel target |

One image can be two things: a current screenshot with annotations is Current + Annotated. Its target is "the current screen with these changes applied", so spec the unmarked areas from the screenshot and the marked areas from the notes.

Tell the dev how you labelled each image. If you can't tell whether an image is the target or the current state, ask. Building the bug back in is worse than asking.

## Step 2: Turn the mockups into a spec

For each **Target** image, and each **Current + Annotated** image, write a short spec. This is the checklist Step 7 compares against. Turn **Annotated** marks into a numbered list of changes; each one gets checked in Step 7 too.

- **Viewport.** Image width tells you the design width. 2880 or 2560 wide usually means a 1440 or 1280 design at 2x. Divide every measurement by the scale.
- **Regions, top to bottom.** Header, filters, table, card, footer: whatever the screen has.
- **Per region:** layout (flex/grid, columns, alignment), sizes, spacing (padding, gaps, margins), typography (family, size, weight, line height, letter case), colors (text, background, border), radius, shadow, icons (which icon, size), and the **exact copy** (same case and punctuation, no rewording).
- **States** shown in the mockups: hover, active, disabled, empty, loading, error, selected. If a state isn't shown but obviously exists (empty table, API error), list it as a question. Don't invent its look.
- **Responsive.** Build to whichever breakpoints have mockups. If there's only a desktop mockup, the smaller sizes must still not break. Ask the dev what they should look like rather than designing them yourself.

Getting values: Figma gives exact numbers. From a PNG, measure in pixels. If Python with Pillow is already installed, sample colors exactly, e.g. `python -c "from PIL import Image; print(Image.open('m.png').convert('RGB').getpixel((x,y)))"`. Otherwise estimate. Don't install anything just for this without asking.

**Map every value to the project's design tokens:** the Tailwind theme, CSS variables, the theme file, the SCSS variables. A measured `#1F2937` that's one shade off `gray-800` is `gray-800`. A measured 15px gap in a 4px/8px spacing system is probably 16px. Use a raw value only when the mockup clearly differs from every token, and list it as a deviation for the dev to confirm. Don't scatter magic numbers.

Conflicts: if the description text and the image disagree, or two images disagree, list it and ask. Don't pick one quietly.

## Step 3: Inventory what to reuse

Before writing anything, search the codebase for what already exists for each region and each piece of logic:

- UI: buttons, inputs, selects, modals, tables, cards, badges, tabs, layout shells, icons, empty states.
- Logic: API client and hooks, formatters (dates, currency, numbers), validators, permission checks, constants and enums.
- Backend: services, selectors, serializers, querysets that already do part of the job.

Search by name and by what it does (`grep` for the component name, the CSS class, the endpoint path, the formatter). Open the closest existing screen to the mockup and copy how it's put together.

Write a reuse table:

```
Region / need          Reuse                          Action
Page header            components/PageHeader.tsx      reuse as is
Status pill            components/Badge.tsx           add "void" variant
Amount column          utils/formatCurrency.ts        reuse
Void confirm modal     components/ConfirmDialog.tsx   reuse, new copy
Invoice summary card   (none)                         new: components/billing/InvoiceSummary.tsx
```

Rules:
- Reuse first, extend second (new prop or variant), create last.
- Never copy-paste a component to tweak it. Extend it, or pull the shared part out.
- A new piece that's likely to be reused goes where the project keeps shared components, named like its neighbours.
- Follow the project's styling system (Tailwind classes, CSS modules, styled-components, whatever it uses). No inline styles, no hard-coded colors where a token exists.
- Logic stays out of UI components, the same way the codebase already does it (hooks, services, selectors).

## Step 4: Check what it affects

- Backend changes (models, endpoints, serializers, tasks): run `impact-analysis`.
- Every shared component, hook or helper you'll **modify**: find every place it's used (`grep` for the import), and list the pages and routes that render it. If you're changing how a shared component looks by default, every one of those pages changes. Prefer a new variant or prop that leaves current callers untouched.
- API responses you change: every frontend or mobile caller that reads them (see `cross-repo-change` / `contract-tests` if it's another repo).
- Tests, Storybook stories and visual snapshots that cover what you're touching.

Write it down as a list with real file paths and page names. "Might affect other screens" isn't an answer.

## Step 5: Show the plan, then wait

Show the dev, short:

1. Ticket summary in one or two lines, plus any comment that overrides the description.
2. The spec from Step 2 (or a link to where you saved it), deviations from tokens, open questions.
3. The reuse table.
4. What it affects (Step 4).
5. Files you'll create or touch.

Wait for a go. Get answers to the open questions first, or agree on a placeholder for each.

## Step 6: Build

- Backend part: follow `django-feature` (or `safe-change` if it changes something shared).
- Frontend part: build region by region against the spec, using the reuse table.
- Tests for behavior, the way the project already writes them: component tests for interactions and states, API tests for endpoints (`test-writer`). Leave pixel-level checking to Step 7. Don't assert CSS values in unit tests unless the project already does.
- Each acceptance criterion maps to at least one test or one checked screenshot.

## Step 7: Compare against the mockups until they match

This step is the point of the skill. Don't skip it, and don't report the UI as done without it.

1. Run the app (use the project's dev command, or the `run` skill) and log in or seed data so the screen shows what the mockup shows. Use the same copy and similar data, so differences come from the code and not from the data.
2. Set the viewport to the mockup's design width (Step 2) and take a screenshot. Use whatever browser tooling is available: a Playwright or Chrome DevTools MCP, Claude in Chrome, or the project's own Playwright (`npx playwright screenshot --viewport-size=1440,900 <url> out.png`). Save it next to the mockup with a matching name.
3. Open the mockup and the screenshot and compare them region by region against the Step 2 spec:
   - layout and alignment, element order
   - sizes and spacing
   - typography (size, weight, line height, case)
   - colors, borders, radius, shadows
   - icons
   - copy, character for character
   - states: trigger each one shown in the mockups (hover, open modal, empty, error) and screenshot it
4. Don't trust your eyes on numbers. Read the computed styles from the browser (`getComputedStyle` on the element, or the DevTools style panel) and check them against the spec values.
5. Fix every difference, then re-screenshot. Repeat until nothing is left, or until the only differences are ones you can't fix (font not licensed locally, real data longer than the mockup's). Stop after 5 rounds and report what's left.
6. If the project already has a visual-diff tool (Playwright `toHaveScreenshot`, pixelmatch, Percy, Chromatic), use it for an overlay diff too. Don't add one without asking.
7. Check the other breakpoints: the ones with mockups must match; the ones without must not break.
8. **Current** images: repeat the steps that produced the screenshot and confirm the problem is gone. **Annotated** images: go through the numbered changes from Step 2 one by one and screenshot each area.

## Step 8: Report

```
ABC-123: Void invoice

Acceptance criteria
1. Admin can void a draft invoice: done (test_void_invoice_admin)
2. Voided invoices show a grey "Void" badge: done (screenshot matched)

Images
- invoice-detail.png (target) ↔ invoice-detail.actual.png: matches
- void-modal.png (target) ↔ void-modal.actual.png: matches except body font falls back to Arial locally (Inter not installed)
- list-bug.png (current + annotated): 3 marked changes, all done; overflow bug no longer reproduces

Reused: PageHeader, Badge (+ "void" variant), ConfirmDialog, formatCurrency
New: components/billing/InvoiceSummary.tsx

Affects
- Badge is used on 6 pages; the new variant is opt-in, existing pages unchanged (checked Invoices, Payments)
- GET /api/invoices/ now returns status "void"; reporting-service handles it (see impact-analysis)

Open questions / follow-ups
- Empty state for the void history list isn't in the mockups: used the existing EmptyState component, needs design sign-off
```

Then next steps: `code-quality` → `pr-description`. Put the mockup and screenshot pairs in the PR so the reviewer can compare without opening Jira.

## Rules

- No UI work without seeing the ticket's images. Stop and ask for them.
- Label every image (target, current, annotated, context) before using it. Only targets are matched pixel for pixel; never copy a current-state screenshot.
- The mockup wins over your taste. Don't "improve" the design, rename labels, or add elements that aren't in it. Raise suggestions as questions.
- When the text, the images and the comments disagree, ask. Newer comments from the designer or PO override older content.
- Reuse before you create, and never fork a component to tweak it.
- Snap to design tokens. Raw values are deviations the dev confirms.
- Don't change the default look of a shared component to satisfy one ticket. Add a variant.
- Never report UI as done without a screenshot comparison at the mockup's width.
- Don't commit downloaded Jira attachments, and never print or commit Jira credentials.
