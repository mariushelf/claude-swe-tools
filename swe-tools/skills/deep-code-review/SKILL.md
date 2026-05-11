---
name: deep-code-review
description: >
  Use when the user wants a deep audit of a codebase or module to find
  silent bugs, wrong-output paths, dead code, and architectural drift —
  beyond what `git grep TODO` or a single linter pass would catch. Spawns
  a multi-wave fan-out of read-only review agents that self-configure
  based on what discovery finds, and synthesises one prioritised
  findings document.
argument-hint: "[scope: <path-or-glob>] [themes: t1,t2,...] [verifier: <prior-review-path>]"
disable-model-invocation: false
---

# Deep Code Review

Multi-wave fan-out of read-only review agents. Each wave informs the next:
discovery → themed deep-dives (parallel) → optional verifier → optional
forensics → unified synthesis. Output is a single prioritised
`SYNTHESIS.md` with severity-tiered findings, file:line evidence, and a
top-N fix-first list.

This skill is **self-configuring**. The discovery agent reads the
codebase and decides which themes apply (including inventing custom
themes for surfaces no pre-tuned template covers); the lead orchestrator
dispatches exactly that set, with a quality floor that always runs four
universals regardless. The skill enforces a methodology, not a fixed
agent count.

## When to use

- Onboarding a codebase someone else owns and needs to be assessed.
- Periodic deep audit before a major release, refactor, or production cutover.
- Re-verification of a prior review's claims after fixes were applied.
- Extracting hidden risks ("what would silently produce wrong output?")
  rather than surface bugs ("what crashes?").

**Don't use** for: a single-file review, a PR review (use `/review`),
generic linting, or design-time questions before code exists (use
`design-advisor`).

## Arguments

`$ARGUMENTS` — optional, parsed for these keys:

- **`scope:`** path or glob to review. Default: current working tree, excluding
  vendored/legacy directories.
- **`themes:`** comma-separated theme names to force-include (overrides
  discovery's recommendation). Default: discovery picks.
- **`verifier:`** path to a prior review document whose claims should be
  re-verified. When present, adds a wave-3 verifier agent.
- **`opus`** (positional): use Opus for all agents. Default: Sonnet.

## Workflow

### Wave 1 — Discovery (single agent)

The lead dispatches one read-only agent with `prompts/lead-discovery.md`.
The agent surveys the project and emits:

1. Prose: what the code does, layout, strengths, 8-12 suspect leads.
2. Theme recommendations (prose): which themes apply, with reasons.
3. A `$PROJECT_CONTEXT` paragraph that every later agent will use.
4. A **machine-readable YAML dispatch block** at the end, listing which
   themes to dispatch (pre-tuned and/or custom) and which to skip.
5. A `production_target: true|false` flag.

Discovery output stays in the conversation, not on disk.

### Wave 2 — Themed deep-dive (parallel, one agent per theme)

The lead **parses the YAML dispatch block** from wave 1 and dispatches
one read-only agent per theme in parallel. Each agent produces one
themed `.md` file under `docs/reviews/<date>-deep-review/`.

#### Always-on themes (medium quality floor)

These four run regardless of what discovery recommended. If discovery
omitted any of them from `themes_to_dispatch`, the lead overrides and
dispatches them anyway — silent-wrong-output and structural-drift
catchers apply universally.

| Theme | Prompt | Output |
|-------|--------|--------|
| `architecture` | `prompts/themed-architecture.md` | `architecture.md` |
| `api-ergonomics` | `prompts/themed-api-ergonomics.md` | `api-ergonomics.md` |
| `dead-code` | `prompts/themed-dead-code.md` | `dead-code.md` |
| `red-team` | `prompts/themed-red-team.md` | `red-team.md` |

#### Conditional pre-tuned themes (dispatched if discovery recommends)

| Theme | When discovery should recommend | Prompt | Output |
|-------|---------------------------------|--------|--------|
| `numerics` | math, statistics, floats, time arithmetic | `prompts/themed-numerics.md` | `numerics.md` |
| `event-flow` | event bus / message queue / webhook / pub-sub / async dispatch | `prompts/themed-event-flow.md` | `event-flow.md` |
| `data-correctness` | I/O boundaries crossing types or schemas (file/network/DB/queue/user input) | `prompts/themed-data-correctness.md` | `data-correctness.md` |
| `llm-correctness` | any call to an LLM provider | `prompts/themed-llm-correctness.md` | `llm-correctness.md` |

#### Custom themes (discovery invents them)

When discovery sees a domain surface no pre-tuned template covers (e.g.
`frontend-state-management`, `iac-correctness`, `embedded-realtime`,
`ml-training-pipeline`, `plugin-system-hygiene`), it emits a custom
theme entry in the dispatch block with:
- a kebab-case `name`
- a 3-4 letter ID `prefix`
- a one-paragraph `rationale`
- a 5-10 bullet `focus_areas` list

The lead instantiates `prompts/themed-custom.md` with these fields and
dispatches it like any other themed agent. Output filename: `<name>.md`.

#### Verifier (only when `verifier:` argument given)

If the user passed `verifier: <path>`, the lead also dispatches a
verifier agent with `prompts/verifier.md`, instantiated with the
prior-review path. Output: `verifier.md`. This runs in wave 3
(after wave 2 has produced new findings to cross-check, or against
the prior review's findings if no new wave 2 ran).

### Wave 3 — Verifier (optional, on-demand)

Two trigger conditions:
1. The user provided a `verifier:` argument (re-verify prior claims).
2. Wave 2 produced findings the lead suspects may be brittle (themed
   agents over-anchor on `$SUSPECT_INVENTORY`; wave 3 is the skeptic).

The verifier reads each cited finding, walks the code path independently,
and classifies CONFIRMED / REFUTED / INCONCLUSIVE. Use
`prompts/verifier.md`.

### Wave 4 — Forensics (optional, on-demand)

If wave 2 or wave 3 surfaces a specific arithmetic, quantitative, or
end-to-end claim that read-only inspection couldn't fully resolve, the
lead dispatches one forensic agent per claim. Each walks the claim
through a worked numerical example, identifies root cause, blast radius,
and a smallest-correct-fix sketch.

Skip this wave if no such claim arose. Use `prompts/forensic.md`.

### Wave 5 — Synthesis (single agent, writes SYNTHESIS.md)

After all wave-2/3/4 outputs land, dispatch one synthesizer with
`prompts/synthesizer.md`. The synthesizer dedupes findings across
themes, resolves conflicts, applies severity tiers (P0/P1/P2 + tags
`LIVE-BLOCKER`, `SECURITY`, `DETERMINISM`, `REGRESSION-RISK`), groups
by theme, and emits a top-N fix-first list with explicit ordering
rationale. This is the document the user will actually read.

The synthesizer also performs a **coverage check**: if a themed review
has thin coverage in a category outlined in its template, it adds a
"review may be incomplete for theme X" entry to "Things still uncertain"
so the user knows where to drill deeper.

## Theme selection — autonomous, with a medium quality floor

The flow is:

1. Discovery agent reads the codebase and emits a YAML dispatch block.
2. Lead parses the block.
3. Lead always dispatches the **four always-on universals** (architecture,
   api-ergonomics, dead-code, red-team), regardless of whether discovery
   listed them. They are the medium quality floor — every codebase has
   these surfaces, and they're cheap.
4. Lead dispatches every conditional / custom theme discovery
   recommended.
5. Lead does **not** dispatch conditional themes discovery skipped (e.g.
   if discovery says "no LLM calls in scope, skip llm-correctness", the
   lead respects that).
6. If the `themes:` argument was passed, it overrides — that exact set
   plus the always-on floor.

`live-readiness` and `concurrency` are deliberately not separate themes
in this skill. Their failure modes are covered by:
- `red-team` category G (failure-as-success), category H (determinism),
  category E (future-data leak / hidden coupling), category F (silent
  type coercion).
- The `LIVE-BLOCKER` synthesizer tag, applied across themes when
  `production_target: true`.
- The always-on `architecture` review for shared-state structural issues.

## Model selection

Use `sonnet` for all teammates by default. Use `opus` only if the user
explicitly requests it (e.g., `/deep-code-review opus`) or for
particularly subtle synthesis on a large codebase.

All themed/verifier/forensic agents are **read-only** — they grep, glob,
and read files but must not edit, write to source, or run tests. They
write their own output `.md` file via Bash heredoc or via a Write-capable
subagent type. Only the synthesizer's output (`SYNTHESIS.md`) is the
user-facing document.

**Subagent type guidance:** prefer `general-purpose` (has the Write tool)
for themed/verifier/forensic/synthesizer agents. Reserve `Explore` for
the wave-1 discovery agent, where the output is consumed in-conversation
rather than written to disk.

## Output layout

```
docs/reviews/<YYYY-MM-DD>-deep-review/
  architecture.md         # always-on
  api-ergonomics.md       # always-on
  dead-code.md            # always-on
  red-team.md             # always-on
  [numerics.md]           # if dispatched
  [event-flow.md]         # if dispatched
  [data-correctness.md]   # if dispatched
  [llm-correctness.md]    # if dispatched
  [<custom-theme>.md]     # one per custom theme
  [verifier.md]           # if wave 3 ran
  [forensic-*.md]         # one per forensic claim
  SYNTHESIS.md            # final unified document
```

## Lead synthesis preamble

After the synthesizer completes, the lead reports back to the user with
a brief summary: number of P0/P1/P2 findings, top-3 fix-first items,
path to `SYNTHESIS.md`, and a one-line note on any custom themes that
were dispatched. Do not paste the full synthesis — point at it.
