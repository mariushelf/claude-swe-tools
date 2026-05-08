# Deep Code Review

A multi-wave, self-configuring code-review skill for Claude Code. Spawns a
fan-out of read-only specialist agents that find silent-wrong-output bugs,
architectural drift, and aspirational dead code — then synthesises one
prioritised findings document.

This README documents the skill's architecture and design philosophy. For
how Claude Code actually invokes it, see [`SKILL.md`](SKILL.md).

---

## What it's for

Catching the bug class linters and PR reviews systematically miss:

- **Silent wrong output** — code that produces an incorrect answer the
  caller trusts, with no exception, log, or visible symptom.
- **Architectural drift** — aspirational structure (hexagonal, layered,
  port/adapter) the code claims but no longer follows.
- **Aspirational dead code** — classes with beautiful docstrings and no
  callers; flags that are never set; `pass`-bodied stubs in production paths.
- **Unsafe defaults** — values that work in dev/sim but cause loss in
  production (silent network fallbacks, default-tenant scoping, RNG seed 0,
  default unlimited retries, etc.).
- **Schema / contract drift** — the docstring says one thing, the code
  another, the consumer assumes a third.

## What it's not for

- PR review on a small diff (use `/review`).
- Single-file review.
- Generic linting (use a linter).
- Design questions before code exists (use `/design-advisor`).

---

## Design philosophy

### 1. The bar is "silent wrong output"

The skill optimises for one specific bug class. A `P0` finding means: in a
default or common configuration, the system silently produces an incorrect
result. The user is being deceived, or the system does something different
from what its API promises. Every other concern is secondary.

| Tier | Definition |
|------|------------|
| **P0** | Silent wrong output in default / common config |
| **P1** | Degraded — knowledgeable users notice; or wrong only in specific configs |
| **P2** | Maintainability — correctness fine, slows evolution |

Orthogonal tags layer on top: `LIVE-BLOCKER` (would cause loss in production
but not in dev/sim), `SECURITY`, `DETERMINISM` (breaks bit-reproducibility),
`REGRESSION-RISK` (a fix could plausibly regress something else).

This bar is what makes the synthesis useful. A list of "30 code smells"
isn't actionable; a list of "5 places where the system silently lies to
its caller" is.

### 2. Themes, not files

A naive review reads file-by-file and produces per-file comments. This
skill asks instead: *what categories of bug live in this code?* Each
category gets one specialist agent with a focused prompt.

A theme is a **lens** — one specific way of looking at the code that
spots one specific class of bug. The numerics lens misses architectural
drift; the architecture lens misses NaN propagation; api-ergonomics
misses event-ordering races. Running multiple specialist lenses in
parallel covers more of the bug surface than any single read-through.

### 3. Discovery decides; orchestrator enforces a floor

The skill is **self-configuring**. The wave-1 discovery agent reads the
codebase and recommends themes (including inventing custom themes for
surfaces no pre-tuned template covers). The lead orchestrator dispatches
exactly that recommendation, with one override: four **always-on
universals** run regardless of what discovery said.

| Decision | Owner |
|----------|-------|
| Which themes apply to *this* codebase? | Discovery agent (judgement) |
| Always run architecture / api-ergonomics / dead-code / red-team | Orchestrator (rule) |
| Skip llm-correctness because there are no LLM calls | Discovery (judgement) |
| Invent a custom `frontend-state-management` theme | Discovery (judgement) |

This factoring separates two concerns. The part that can't be wrong
(every codebase has architecture, an API surface, dead code, and silent
wrong-output paths) is in the always-on floor. The part that requires
judgement (which domain themes apply, what custom themes to invent) is
in discovery. A confused discovery agent can't make red-team disappear;
a bad floor heuristic can't suppress something discovery flagged.

The handoff between discovery and the orchestrator is a **machine-readable
YAML dispatch block** at the end of discovery's output. Making the
contract explicit (named themes, prefixes, focus areas, skip reasons)
keeps dispatch deterministic and makes a bad discovery report visible —
you can read the YAML and immediately spot "wait, this code calls Anthropic
and discovery said skip llm-correctness."

### 4. Read-only, multi-wave, fan-out

Every agent is read-only. They grep, glob, and read files; they don't
edit code, run tests, or modify state. The only writer of new content is
the synthesizer (which produces `SYNTHESIS.md`).

Waves are sequential; agents within a wave run in parallel.

```
Wave 1 — Discovery (1 agent)
  Reads codebase. Emits prose survey + YAML dispatch block.

Wave 2 — Themed deep-dive (N agents, parallel)
  4 always-on universals + conditionals discovery recommended + custom themes.
  Each writes one <theme>.md file with finding IDs and severity tiers.

Wave 3 — Verifier (1 agent, optional)
  Re-walks claims from wave 2 (or from a prior review). Classifies each
  finding CONFIRMED / REFUTED / INCONCLUSIVE / RE-TIERED.

Wave 4 — Forensic (M agents, optional, one per claim)
  Worked numerical example for one specific P0. Root cause, blast radius,
  smallest-correct-fix sketch.

Wave 5 — Synthesis (1 agent)
  Reads everything. Dedupes, resolves conflicts, tiers, groups, ranks,
  identifies recurring patterns. Writes SYNTHESIS.md.
```

Why multi-wave instead of one large agent?
- **Specialisation beats generalisation.** A focused prompt produces
  deeper findings than a "review everything" prompt of equal length.
- **Context isolation.** Each themed agent's context window holds only
  its theme's surface; nothing fights for room.
- **Parallelism.** Five themed agents in parallel is ~5× wall-clock
  faster than one sequential review.
- **Composability.** Wave 3 (verifier) can run standalone against a
  prior review without re-running the themed reviewers.

### 5. Synthesis is the document; everything else is appendix

The user reads `SYNTHESIS.md`. Everything else is evidence cited from it.
The synthesizer's job is the part that's hardest to do as a human after
the fact: dedupe across themes, resolve conflicts, apply severity tiers
and tags, group by theme, pick the 8-12 highest-leverage fixes with
ordering rationale, identify 2-5 recurring patterns that explain the
bulk of P0s, and flag forensic follow-up candidates.

Without this step you have N themed `.md` files and no idea where to
start. With it you have one prioritised list and the option to drill
down.

The synthesizer also runs a **coverage check**: if a themed review came
back thin in a category outlined in its template (e.g., red-team's
adversarial categories A-H), it adds a "review may be incomplete for
theme X" entry to "Things still uncertain" so the user knows where to
push back. This is a check on the themed agents' tendency to over-anchor
on the discovery agent's suspect inventory and miss generic enumeration.

---

## Theme catalogue

### Always-on (the medium quality floor)

| Theme | Lens |
|-------|------|
| `architecture` | Layering violations, leaky abstractions, coupling, duplicated abstractions |
| `api-ergonomics` | Bad defaults, implicit invariants, naming traps, extension hooks, error/observability quality |
| `dead-code` | Unwired classes, aspirational stubs, duplicate concepts, unreachable branches, leftover scaffolding |
| `red-team` | Silent-wrong-output adversarial enumeration across 8 categories (boundaries / ordering / config drift / composition / future-data leak / type coercion / failure-as-success / determinism) |

### Conditional pre-tuned

| Theme | Triggered when… |
|-------|-----------------|
| `numerics` | Math, statistics, floats, time arithmetic |
| `event-flow` | Event bus / message queue / webhook / pub-sub / async dispatch / state-change-triggers-reaction |
| `data-correctness` | I/O boundaries crossing types or schemas (file / network / DB / queue / user input) |
| `llm-correctness` | Any call to a language-model API (OpenAI, Anthropic, Bedrock, LiteLLM, LangChain, local model, …) |

### Custom (discovery invents them)

When the codebase has a domain surface no pre-tuned template covers,
discovery generates a custom theme via the `themed-custom.md`
meta-template. Examples discovery might invent:
`frontend-state-management`, `iac-correctness`, `embedded-realtime`,
`ml-training-pipeline`, `plugin-system-hygiene`,
`build-cache-correctness`. Each gets a kebab-case name, a short ID
prefix, and a 5-10 bullet focus list grounded in what discovery found.

### Two themes deliberately omitted

`concurrency` and `live-readiness` are **not** separate themes. Their
failure modes are already covered:

- **Concurrency races** → `red-team` category E (future-data leak /
  hidden coupling), category G (failure-as-success), category H
  (determinism); plus `architecture` for shared-state structural issues.
- **Live-readiness** → the `LIVE-BLOCKER` synthesizer tag, applied
  across themes when discovery sets `production_target: true`.

Adding these as standalone themes duplicated work without surfacing new
findings.

---

## Output

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
  [<custom-theme>.md]     # one per custom theme discovery invented
  [verifier.md]           # if wave 3 ran
  [forensic-*.md]         # one per forensic claim (wave 4)
  SYNTHESIS.md            # ← start here
```

## How to read a SYNTHESIS

Open `SYNTHESIS.md` and read in order:

1. **Executive summary** — 3-5 paragraphs distilling the codebase's
   correctness posture and the 2-4 patterns explaining the P0s.
2. **Severity tally** — counts by tier and tag.
3. **Top-N fix-first list** — start here for action; ordered by
   leverage, with a one-paragraph "why this one before others."
4. **Findings by theme** — per-theme tables with severity, evidence
   pointer (file:line), and a `Fix` column for tracking remediation.
5. **Recurring root causes** — 2-5 patterns; fix categories not
   instances.
6. **Things still uncertain** — candidates for forensic follow-up.

Each finding has a stable ID (e.g. `RT-03`, `LLM-07`, `DAT-12`,
`FSM-02`). When you fix one, mark the `Fix` column. The document is
intended to be a living artefact across multiple review/fix cycles.

---

## Usage

```bash
/deep-code-review                                  # full repo, autonomous
/deep-code-review scope: src/auth                  # subdirectory only
/deep-code-review themes: numerics,api-ergonomics  # force specific themes
                                                   # (always-on floor still runs)
/deep-code-review verifier: docs/reviews/2025-12-01-deep-review/SYNTHESIS.md
                                                   # re-verify a prior review
/deep-code-review opus                             # use Opus for all agents
```

Default model: Sonnet. Default scope: working tree minus
`vendored/`, `legacy/`, `third_party/`, `.venv/`.

---

## Limits

- **Read-only.** Cannot run tests, profile code, or detect runtime
  behaviour. Symbols loaded by reflection, dispatched by name, or
  registered by side-effect-on-import may be misclassified as dead.
  The dead-code prompt's adversarial-self-check step partially
  mitigates this.
- **Skews toward subtle bugs.** A trivial off-by-one in a function
  nobody calls is unlikely to surface. A subtle off-by-one in a
  default-argument expression of a frequently-called public function
  is exactly the target.
- **Discovery is load-bearing.** A bad discovery report cascades. The
  always-on floor mitigates for four universals; the synthesizer's
  coverage check is the second line of defence; on a codebase you
  know well you can override discovery via the `themes:` argument.
- **Cost scales with codebase × theme count.** Default Sonnet is
  reasonable for medium repos. Opus is worth the upgrade primarily
  for the synthesizer on large or unfamiliar codebases.
- **No feedback loop yet.** The skill currently doesn't track which
  findings were marked false-positive across runs. The `Fix` column
  in SYNTHESIS.md is the only longitudinal signal.

---

## Layout

```
deep-code-review/
  README.md                       # this file
  SKILL.md                        # invocation contract for Claude Code
  prompts/
    lead-discovery.md             # wave 1
    themed-architecture.md        # wave 2 — always-on
    themed-api-ergonomics.md      # wave 2 — always-on
    themed-dead-code.md           # wave 2 — always-on
    themed-red-team.md            # wave 2 — always-on
    themed-numerics.md            # wave 2 — conditional
    themed-event-flow.md          # wave 2 — conditional
    themed-data-correctness.md    # wave 2 — conditional
    themed-llm-correctness.md     # wave 2 — conditional
    themed-custom.md              # wave 2 — meta-template for custom themes
    verifier.md                   # wave 3
    forensic.md                   # wave 4
    synthesizer.md                # wave 5
```
