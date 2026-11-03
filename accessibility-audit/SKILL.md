---
name: accessibility-audit
description: Audit a page, component or flow against WCAG 2.2 AA - semantics and landmarks, form labels, keyboard navigation and focus order, visible focus, color contrast, alt text, ARIA misuse, motion and target size - using axe/Lighthouse where available plus manual keyboard and screen-reader checks, and report findings with file:line and the fix. Use when "is this accessible", "check a11y", "we need WCAG compliance", "a client asked for an accessibility report", "keyboard users can't use this", or before launching a public page.
---

# Accessibility Audit

Find real barriers, tie each one to code, and give the fix. Automated tools catch maybe a third of issues; the keyboard and screen-reader passes are not optional.

## Step 0: Read the stack

Find the UI framework, the component library (Radix, Headless UI, MUI, Angular Material, native elements), and any a11y tooling already set up: `eslint-plugin-jsx-a11y`, `@axe-core/playwright`, `jest-axe`/`vitest-axe`, `pa11y`, Storybook a11y addon. Use what's there before adding anything. Check whether the shared components (Button, Modal, Menu, Input) are custom or from a library; custom ones are where most bugs live.

## Step 1: Scope

Agree on the pages or flows (login, signup, checkout, the main dashboard) and the target: WCAG 2.2 AA unless the client says otherwise. Start the app with the repo's dev command and use realistic data.

## Step 2: Automated pass

- `npx @axe-core/cli <url>`, or an axe check in the repo's e2e runner (`new AxeBuilder({ page }).withTags(["wcag2a","wcag2aa","wcag22aa"]).analyze()`).
- Lighthouse accessibility category (`npx lighthouse <url> --only-categories=accessibility`).
- The repo's a11y lint rule, if configured.

Run on every state of the flow (open modals, error states, expanded menus), not only the initial load.

## Step 3: Manual pass

1. **Keyboard only**: Tab through the whole flow. Every interactive element reachable, in a logical order, operable with Enter/Space/arrows/Escape as expected. No traps. Modals move focus in, keep it there, and return it on close. Skip link present on pages with long navigation.
2. **Focus visible**: every focused element has a clear indicator, not hidden behind sticky headers or banners (2.4.11).
3. **Semantics**: one `h1`, headings in order, landmarks (`header`, `nav`, `main`, `footer`), lists as lists, tables with `th`/`scope`. `div`/`span` with `onClick` is a bug; use `button` or `a`.
4. **Forms**: every input has a programmatic label (`<label for>`, `aria-labelledby`); errors announced and linked with `aria-describedby`; required fields marked in text, not only color; no re-asking for info already entered (3.3.7).
5. **Images and icons**: meaningful images have alt text describing purpose; decorative ones `alt=""`; icon-only buttons have an accessible name.
6. **Contrast**: text 4.5:1 (3:1 for 18.66px bold / 24px+), UI components and focus rings 3:1. Check hover, disabled-looking-but-enabled, and placeholder text.
7. **ARIA**: no ARIA is better than wrong ARIA. Look for `role="button"` without keyboard handlers, `aria-hidden` on focusable elements, `aria-label` that disagrees with visible text, live regions missing for toasts and async results.
8. **Motion and targets**: animations respect `prefers-reduced-motion`; nothing flashes more than 3 times per second; targets at least 24x24px (2.5.8); drag interactions have a click alternative (2.5.7).
9. **Screen reader spot check**: NVDA (Windows) or VoiceOver (macOS: Cmd+F5) on the main flow. Does each control announce name, role and state?
10. **Zoom and reflow**: 200% zoom and 320px width with no loss of content or horizontal scroll.

## Step 4: Report

Rank by user impact (blocks a task > makes it hard > annoyance):

```
[Blocker] Modal close button has no accessible name   WCAG 4.1.2
Where: src/components/Modal.tsx:58  <button onClick={onClose}><XIcon/></button>
Found by: axe (button-name), NVDA reads "button"
Fix: aria-label="Close dialog" on the button; aria-hidden on the icon
Affects: every modal (shared component)
```

Group repeats from one shared component into one finding. Offer `jira-tickets` for the list.

## Step 5: Fix (if asked)

Fix in shared components first; one change there clears many findings. Add a regression check where the repo can host it: an axe assertion in the e2e test for the flow, or `jest-axe`/`vitest-axe` on the component. Re-run Steps 2-3 on what changed.

## Rules

- Every finding has a WCAG criterion, a file:line, evidence (tool rule id or manual step), and a concrete fix.
- A clean axe run is not "accessible". Always do the keyboard pass.
- Prefer native HTML elements over ARIA rebuilds of them.
- Don't promise legal compliance; report against WCAG 2.2 AA.

Next: `ui-polish` for the visual follow-ups, `e2e-tests` to keep the axe checks in CI.
