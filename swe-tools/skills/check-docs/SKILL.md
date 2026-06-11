---
name: check-docs
description: >
  Use when a Python repository's documentation might be missing, stale,
  contradicted by the code, mis-structured, or off-voice, and a read-only
  assessment is wanted before anything is changed — before running
  update-docs, as a CI or pre-PR gate, or when inheriting an unfamiliar
  codebase. Produces a DOC_AUDIT.md and never touches a documentation page.
argument-hint: "[scope: <path>] [since: <ref|date>] [range: <a>..<b>] [out: <report-path>]"
disable-model-invocation: false
---

# Check Docs

A read-only audit of a Python repository's documentation against its source
code. It surveys the repo, fans out cheap parallel agents across four lenses —
coverage, drift, structure, voice — and synthesises a single prioritised
`DOC_AUDIT.md`. **It never touches the rendered docs tree or any existing
file.** The only file it creates is the report (by default under
`docs/reviews/`, which is not rendered).

The report is the contract with the writer skill, `update-docs`: every finding
carries a per-page `action` that a human can edit, and `update-docs` consumes
the curated report. This skill observes; `update-docs` mutates.

## When to use

- Before running `update-docs`, to see (and curate) what it would change.
- As a CI or pre-PR gate that flags documentation drift without touching files.
- When inheriting a repository whose documentation you do not yet trust.
- To answer "what is undocumented / wrong / in the wrong place?" without risk.

**Don't use** for: making the fixes (use `update-docs`), reviewing code rather
than docs (use `deep-code-review`), or a single-file proofread.

## Arguments

`$ARGUMENTS` — optional. The keys below are a vocabulary, not a grammar: plain
prose works too (`only audit the clustering service`), and is interpreted into
the same effect. Default: the repository's `docs/` plus the public surface of the
package under `src/` (or the flat package).

- **`scope:`** what to audit. Accepts a code path (`src/pkg/services/`), a docs
  path (`docs/source/architecture/`), or a prose description of a module or
  subtree. A code path is mapped to the docs pages that should cover it; a docs
  path is audited directly.
- **`out:`** where to write the report. Default: `docs/reviews/<date>-doc-audit/DOC_AUDIT.md`.
- **`since:`** a recency anchor — a ref, tag, sha, or date. Resolved to a
  *boundary commit*; everything changed between it and `HEAD` is the **window**,
  and the audit is narrowed to the documentation that window touches (see
  *Recency narrows the audit*). A date resolves as `git rev-list -1 --before="<date>" <branch>` (the last
  commit on/before that date) — never raw `git log --since`, whose ordering
  rebases and squash-merges corrupt. **Given with no value, it defaults to the
  commit that produced the newest existing `docs/reviews/**/DOC_AUDIT.md`**
  (`git log -1 --format=%H -- <that file>`), so the natural anchor is "since the
  last audit." If no prior report exists, a value is required.
- **`range:`** an explicit `<a>..<b>` commit range, used verbatim instead of
  deriving a boundary from `since:`.

### Scoped runs stay in their lane

When `scope:` (or prose) narrows the run to a module or subtree, every wave is
restricted to it. Pages and code outside the scope are **read-only context** —
discovery may consult them to resolve cross-references, but no lens flags them.
In particular the structure lens does not report out-of-scope orphan pages or
missing pairs; it assesses structure only within the scoped subtree. A scoped
audit answers "what is missing or wrong *here*," not "is the whole site correct."

### Recency narrows the audit

`since:`/`range:` resolves to a **window** — the commits between a boundary and
`HEAD` — and uses it to **scope the audit down to the documentation that change
touched**. This is the cheap, focused path: point it at recent history and get
back the doc debt *for those changes*, without paying to re-audit the whole site.

The in-scope page set is the union of:

- **doc pages changed in the window**, and
- **doc pages that should cover code changed in the window** (resolved through
  the site-map).

Only those pages are audited. Code and pages the window did not touch are
read-only context — discovery may consult them to resolve cross-references, but
no lens flags them, exactly as under `scope:`.

Two things the narrowing deliberately does **not** weaken:

- **Each in-scope page is audited in full.** Scoping decides *which* pages are
  checked, never *how thoroughly*. Every applicable lens still runs over each
  in-scope page against current source — a page is never half-checked just
  because only one of its claims sits near the change.
- **The report is honest that it is partial.** A windowed run is a **partial
  audit by design**, and the preamble says so up front. The absence of findings
  means "nothing wrong in what changed," never "the docs are otherwise fine."
  For a full-site verdict, run without `since:`/`range:`.

Within the in-scope set, the **doc-diff signal** sets priority: code that churned
in the window while its covering page did *not* is the likeliest stale page and
sorts first. It is a priority hint, not a verdict — a page whose doc was also
edited can still be wrong — so it changes ordering, not what gets audited.

Resolve the window once, deterministically, in the orchestrator:
`git diff --name-status -M <boundary>..HEAD`, split into code and doc paths
(`-M` so pure renames register as path-only, low-priority churn). Combine with
`scope:` to narrow further still — the in-scope set is then the intersection.

## The target documentation model

The audit measures the repo against the model `update-docs` produces — a
Diátaxis structure organised first by audience (orientation / users / operators
/ maintainers), rendered by Sphinx + MyST, where **only `docs/source/` is
rendered**. The rules come from two places, in order of precedence:

1. **The repo's own meta-layer** (its `voice.md` / documentation guide,
   wherever they live under `docs/`) — the local law, when present.
2. **The self-contained summaries embedded in the audit prompts** — the
   canonical fallback, kept aligned with `update-docs/assets/meta/`.

Subagents never read files from the sibling `update-docs` skill — cross-skill
paths do not resolve reliably from a dispatched agent, which is why the
prompts carry their own summaries.

## Workflow

A self-configuring fan-out modelled on `deep-code-review`: discovery decides what
applies, the orchestrator dispatches exactly that set. Discovery and synthesis
use a capable model; the audit lenses use a cheap model (the work is narrow and
mechanical). One agent per lens × area caps tail latency.

Waves A and B are read-only by contract: dispatch them as read-only subagents
where the harness offers a type without write tools (e.g. `Explore`), so the
no-writes guarantee is mechanical, not just instructed.

### Wave A — Detect and map (1 agent, capable model)

Dispatch one read-only agent with `prompts/discovery.md`. It surveys the repo —
package layout, `pyproject`, existing docs (none / legacy-Sphinx / legacy-MD /
MkDocs), test and CI layout, whether copier-scaffolded, whether hexagonal, the
public API surface — classifies each existing doc by type and audience, maps it
to a target home, and emits:

1. A `$PROJECT_CONTEXT` paragraph every later agent reuses.
2. A site-map: the pages that should exist, and where each existing doc belongs.
3. An auto-estimated `mode` recommendation (`auto` / `touch-up` / `overhaul`).

When a window is active, discovery also receives `$WINDOW` and `$CHANGED_PATHS`
and restricts the site-map and the lens area-lists to the **in-scope page set** —
the doc pages changed in the window plus the pages that should cover code changed
in the window. It marks which of those pages cover churned code whose doc did
*not* change (the likely-stale signal) so the report can sort them first. Pages
the window did not touch become read-only context, exactly as under `scope:`.

Discovery output stays in the conversation, not on disk.

### Wave B — Audit fan-out (parallel, cheap model)

Dispatch the lenses that apply, in parallel, each over the areas discovery
surfaced. Which lenses apply depends on the doc-state discovery classified:

| Doc state | Lenses |
|-----------|--------|
| none (no docs at all) | coverage only — there is nothing to drift, structure, or voice-check |
| legacy-MD / legacy-Sphinx / MkDocs | coverage + drift + structure; voice only if the repo carries its own voice rules or an overhaul is on the table |
| target model (`docs/source/` + meta-layer) | all four |

Each agent emits findings only — no fixes, no file writes — with `file:line`
evidence and a proposed per-page `action`. Give every agent a short `$AREA_ID`
(e.g. `api`, `services`) — finding IDs are `<LENS>-<area>-NNN`, so parallel
same-lens agents cannot collide; the report re-keys them.

| Lens | Prompt | Finds |
|------|--------|-------|
| coverage | `prompts/audit-coverage.md` | Undocumented public surface, endpoints, settings, architecture. |
| drift | `prompts/audit-drift.md` | Doc claims contradicted by current source. |
| structure | `prompts/audit-structure.md` | Misplaced pages, missing `toctree` entries, wrong Diátaxis/audience placement, `docs/source/` violations. |
| voice | `prompts/audit-voice.md` | Violations of the voice rules. |

Coverage and drift are the per-doc cheap-subagent fan-out — split large repos by
area so each agent stays small.

### Wave C — Synthesise report (orchestrator, capable model)

Merge and deduplicate the lens findings into one prioritised `DOC_AUDIT.md`
using `prompts/report.md`. The report **must open with a self-documenting
"How to use this report" preamble** (how to read findings, edit the `action`
field, and hand the file to `update-docs`). Each finding records id, type,
severity, `file:line` evidence, a suggested fix, an auto-estimated `action`,
and — for `create`/`overhaul` — a **Target** docname and page type. The report
also embeds the project-context paragraph, so `update-docs report:` consumes it
without re-deriving anything. Write only the report file; touch no other file.

When a window is active, pass `$WINDOW` and `$CHANGED_PATHS` to the report: every
finding is in-scope by construction, so the report carries the partial-audit
disclaimer (it audited only what the window touched, not the whole site) and
sorts likely-stale pages — churned code whose covering doc did not change — first.

### Filling the prompts

Every placeholder, and who provides it:

| Placeholder | Used by | Source |
|-------------|---------|--------|
| `$ARGUMENTS` | discovery | the raw skill arguments, verbatim |
| `$SCOPE` | discovery, all lenses | the parsed `scope:` value (or "whole repo"); for lenses, narrowed further to the agent's assigned areas |
| `$AREA_ID` | all lenses | short orchestrator-chosen area label per agent |
| `$PROJECT_CONTEXT` | all lenses, report | discovery output 1 |
| `$SITE_MAP` | coverage, structure, report | discovery output 2 |
| `$MODE_RECOMMENDATION` | report | discovery output 3, with its one-sentence rationale |
| `$LENS_FINDINGS` | report | concatenated Wave B outputs |
| `$OUT_PATH` | report | the parsed `out:` value or the dated default |
| `$WINDOW` | discovery, report | the resolved `<boundary>..HEAD` range, or "none" |
| `$CHANGED_PATHS` | discovery, report | the windowed change set (code/doc split), or "none" |

## The `action` taxonomy

Every finding carries an `action` — the per-page intervention, auto-estimated
and human-editable:

- `touch-up` — patch/correct in place; keep structure and prose.
- `overhaul` — restructure into `docs/source/`, rewrite to voice, regenerate.
  For a page documenting a removed feature, the overhaul may consist of
  deleting the page (or folding any still-true remnant into another page).
- `create` — greenfield gap; author fresh from code.
- `leave` — fine as-is, or human-only work (an ADR gap a maintainer must
  fill); recorded for completeness, never acted on.
- `skip` — human veto; do not touch even though a fix was suggested.

## Output

A single `DOC_AUDIT.md`. No separate machine-readable manifest — the consumer is
an LLM that reads markdown directly. See `README.md` for the human workflow:
read the report, edit `action`s, then run `update-docs report:<path>`.
