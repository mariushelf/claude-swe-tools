PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
INPUT_DOCS: $INPUT_DOCS  (list of paths to all themed review files + any forensic / verifier outputs)

YOUR ROLE: Synthesizer. Read every input doc and produce a single
unified, prioritised, deduplicated, conflict-resolved findings document.
This is the document the user will actually read — every other doc
becomes appendix.

You CAN write to disk: your output goes to
`docs/reviews/<DATE>-deep-review/SYNTHESIS.md`.

STEP 1 — Deduplicate.
Many findings appear in multiple themed reports under different IDs.
For each duplicate, merge into a single canonical finding with
consolidated evidence (cite all the source IDs). Examples of common
duplications across themes:
- "Bad default" appears in API ergonomics, red-team, AND architecture.
- "NaN propagation" appears in numerics, red-team, AND data-correctness.
- "Unwired aspirational class" appears in dead-code AND architecture.

STEP 2 — Resolve conflicts.
If two themes disagree about whether a finding is real, severe, or
already-mitigated, decide based on evidence weight. Note the conflict
explicitly — don't silently pick a side. Use a "REFUTED" status with
a one-line reason for findings that fall away on closer inspection.

STEP 3 — Apply severity tiers.
- **P0 (silent wrong-output)** — the system silently produces an
  incorrect result in a default or common configuration. Either the
  user is being deceived or the system is doing something different
  from what its API promises.
- **P1 (degraded)** — knowledgeable users could detect the problem;
  or correctness issue only triggered by specific configurations.
- **P2 (maintainability)** — code-quality issues that don't affect
  correctness but slow evolution.
- **EXTRA TAGS** (orthogonal to severity, may apply with any tier):
  - `LIVE-BLOCKER` if the codebase has a "production" target and this
    finding would cause loss in that environment but not in
    development / sim.
  - `SECURITY` if it's a security issue.
  - `DETERMINISM` if it breaks bit-reproducibility.
  - `REGRESSION-RISK` if a fix could plausibly regress something else.

A finding can carry both a tier and one or more tags.

STEP 4 — Group by theme.
Use the same themes that produced the input docs, in the order:
data correctness, event flow, llm correctness, architecture, API
ergonomics, numerics, dead code, red-team, plus any custom themes
discovery generated. Skip themes with zero findings.

STEP 5 — For each finding, format as a row in a per-theme table:

| ID | Title | Evidence (file:line) | Severity | Status |

Plus a one-paragraph "what's wrong / why it matters" for any P0 or
LIVE-BLOCKER finding. P1 / P2 can be one-line summaries in the table.

STEP 6 — Top-N fix-first list.
Pick the 8-12 highest-leverage fixes. For each, give:
- Why this one before others (root-cause-amplifier vs leaf, cheapest
  catastrophic-payoff, blocks others, etc.).
- Estimated blast radius of the fix.
- Whether fixing this surfaces or masks other findings.

Open with a one-paragraph "ordering rationale" explaining the picks.

STEP 7 — Recurring themes / root causes.
Identify 2-5 architectural patterns that explain the bulk of the P0s.
Examples (your project may have different ones):
- "trust-the-caller without invariant guards"
- "events emitted from two places, deduped at neither"
- "future-data leak is a structural default, not an accident"
- "silent defaults replace user intent"
- "aspirational code sitting next to working code"
- "external-system response shape assumed, never validated"
For each pattern, list the findings that fall under it. This section
helps the user fix categories rather than instances.

STEP 8 — Things still uncertain.
Honest tail. List any findings that the input docs disagree on without
clear evidence, or any place the read-only review couldn't fully
resolve a claim. These are candidates for forensic follow-up.

**Coverage check.** Inspect each input theme report for breadth. If a
themed review has fewer than ~3 findings in a major category outlined
in its template (e.g., red-team's adversarial categories A-H, numerics'
sub-themes 1-8), add a "review may be incomplete for theme X" entry to
"Things still uncertain". Themed agents over-anchor on
`$SUSPECT_INVENTORY` items and miss generic enumeration; flag this when
you see it so the user knows where to drill deeper.

OUTPUT: write to `docs/reviews/<DATE>-deep-review/SYNTHESIS.md`.

Length: 2500-4500 words depending on input volume. Make it
skim-friendly: tables, headers, bullets. Lead with the executive
summary. Each section gets evidence + severity, not narrative.

Open with:
1. **Executive summary** — 3-5 paragraphs distilling the codebase's
   correctness posture and the 2-4 patterns explaining the P0s.
2. **Severity tally** — counts by tier and by tag.
3. **Top-N fix-first** (the table from step 6).
4. **Findings by theme** (the per-theme tables from step 5).
5. **Recurring themes / root causes** (from step 7).
6. **Things still uncertain** (from step 8).

Add a `Fix` column to each per-theme table, all values `—`. This is
where remediation status will be tracked over time.
