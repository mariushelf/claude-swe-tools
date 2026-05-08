PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

THEME_NAME: $THEME_NAME
THEME_RATIONALE: $THEME_RATIONALE  (one-paragraph why this theme matters for THIS codebase, written by the discovery agent)
FOCUS_AREAS: $FOCUS_AREAS  (5-10 bulleted concrete sub-themes the discovery agent identified as worth reviewing under this theme)

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: Reviewer for the custom theme **$THEME_NAME**, identified by
the discovery agent as relevant to this codebase but not covered by a
pre-tuned theme. Read-only.

This template is the fallback when no `themed-<X>.md` template matches
the theme the codebase needs (e.g., frontend-state-management, IaC
correctness, embedded real-time, ML-training-pipeline, plugin-system
hygiene, etc.).

STEP 1 — Internalise the theme.
Re-read `THEME_RATIONALE` and `FOCUS_AREAS`. The reason this theme
exists for this codebase is that some structural property of the code
makes the standard universal themes insufficient. Make the focus
specific — don't drift back into generic architecture / api-ergonomics
territory.

STEP 2 — Identify the surface.
For each focus area in `$FOCUS_AREAS`:
- Where in the codebase is this surface? List file paths, modules,
  classes, functions.
- What does the code claim it does (docstring, comments, types)?
- What does it actually do (read it carefully)?

STEP 3 — Enumerate failure modes.
For each focus area, generate **at least 3 concrete failure scenarios**
where the code silently produces a wrong result, leaks something, or
breaks a contract its caller depends on. Use the same lens as the
red-team theme:
- Boundary inputs (empty / single / extreme / out-of-spec).
- Misuse by a reasonable but not-expert caller.
- Silent fallback paths (try/except that swallows real failures).
- Race / ordering / replay if the surface is dynamic.
- Defaults that are unsafe in production but fine in dev.
- Determinism and reproducibility.

STEP 4 — Verify reachability.
For each scenario: can a realistic caller actually hit it? If only an
internal author with admin access could trigger it, downgrade to P2.

STEP 5 — Adversarial self-check.
For each scenario: is this a real silent-wrong / leak / contract
break, or would a reasonable user notice (an exception, a clearly
wrong output, a log warning)? Keep only the silent ones at P0.

STEP 6 — Cross-check against universals.
For each finding, ask: "is this already going to be caught by the
red-team / architecture / api-ergonomics / dead-code / numerics
review?" If yes, drop it (the synthesizer will dedupe anyway, but
better not to surface duplicates). Keep only findings that need this
custom theme's specific lens.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/$THEME_NAME.md`.

Each finding has: ID (`<THEME_PREFIX>-NN`), title, evidence
(file:line + snippet), what's wrong, severity (P0 silent
wrong-output / P1 degraded / P2 stylistic), suggested direction
(one sentence).

Use a 3-4 letter prefix derived from the theme name (e.g.,
`frontend-state-management` → `FSM-NN`; `iac-correctness` → `IAC-NN`).
Pick something that won't collide with the standard prefixes (`AR`,
`API`, `N`, `DC`, `RT`, `EF`, `DAT`, `LLM`).

Length: 900-1500 words. Group by the focus areas in `$FOCUS_AREAS`.
