---
name: update-docs
description: >
  Use when a Python repository's documentation must be created from code
  (greenfield), brought back in line with the code, restructured into a
  proper Sphinx/Diátaxis layout, or corrected for voice — and you want the
  files actually written and wired, not just a report. Handles both
  no-docs-yet and stale-legacy-docs repositories. Writes to docs/.
argument-hint: "[report: <doc-audit-path>] [mode: auto|touch-up|overhaul] [scope: <path>]"
disable-model-invocation: false
---

# Update Docs

Creates, repairs, and restructures a Python repository's documentation against
its source code, then wires and build-verifies it. It works on greenfield repos
(derive docs from code) and legacy repos (re-verify facts, restructure, rewrite
to voice). It is the writer counterpart to the read-only `check-docs` skill.

The target is a Diátaxis structure organised first by audience, rendered by
Sphinx + MyST, where **only `docs/source/` is rendered** so development files can
sit beside the docs unrendered. The conventions and voice are carried in
`assets/`.

## When to use

- A repository has no documentation and it must be derived from the code.
- Documentation exists but is stale, mis-structured, or contradicted by code.
- A curated `DOC_AUDIT.md` from `check-docs` needs to be applied.
- A new concept, endpoint, or subsystem needs its documentation written.

**Don't use** for: a read-only assessment (use `check-docs`), or reviewing code
(use `deep-code-review`).

## Arguments

`$ARGUMENTS` — optional. The keys below are a vocabulary, not a grammar: plain
prose works too (`only document the clustering service, leave the rest`), and is
interpreted into the same effect.

- **`report:`** path to a `DOC_AUDIT.md` (typically from `check-docs`, optionally
  human-curated). When present, **trust it completely** — see *Report mode*.
- **`mode:`** `auto` (default) / `touch-up` / `overhaul` — the global cap over
  per-finding actions. See *The mode cap*.
- **`scope:`** what to work on. Accepts a code path (`src/pkg/services/`), a docs
  path, or a prose description of a module or subtree. Default: the whole
  repository. A code path is mapped to the docs pages that should cover it.

### Scoped runs stay in their lane

When `scope:` (or prose) narrows the run, U1–U4 act only on the scoped subtree
and its corresponding pages. Pages outside the scope are left untouched — they
are read-only context for resolving cross-references, never restructured,
rewritten, or flagged. If no report was passed, the `check-docs` invocation
inherits the same scope, so its structure lens does not report out-of-scope
pages.

One exception is deliberate: **U5 build-verify always runs `make docs-strict` on
the whole site**, because a scoped change can still break the global `toctree` or
a cross-reference into the rest of the docs. Wiring is limited to the pages this
run changed, but the build check is repo-wide so a local edit cannot silently
break the published site.

## Where the work-list comes from

`update-docs` does not start by exploring. It obtains a list of findings — each
with an `action` — one of two ways:

1. **`report:<path>` given** → load it and act on it directly (Report mode).
2. **No report** → invoke the `check-docs` skill (via the Skill tool) to produce
   one, then act on the auto-estimated actions.

Composition is by skill invocation, not by importing `check-docs`'s prompt files
— that keeps the audit logic single-source in `check-docs`.

### Report mode: trust, do not explore

When `report:` is given, do **no** discovery, re-audit, or re-derivation of
drift. The curated report *is* the complete work-list. Execute each finding's
`action`. (You still ground any prose you write in current source and self-check
your own new claims — that is authoring hygiene, not re-auditing the repo.)

The report is self-sufficient: its `## Project context` section supplies the
`$PROJECT_CONTEXT` every prompt expects, and each `create`/`overhaul` finding
carries a **Target** line (docname + page type) that picks the U2 prompt and
`$TARGET_PATH`. A `touch-up` finding's target is its **Location** page. If a
report lacks these fields (hand-written, or from an older audit), derive the
missing targets from the findings' Fix lines and say so in the U5 report — do
not silently re-audit.

### Building the work-list

From the findings (after the `mode` cap):

1. Drop `skip` and `leave` findings.
2. If `scope:` is given, drop findings whose target page falls outside it.
3. **Group the remainder by target page.** Several findings often hit one page
   (a drift fix plus a voice note); dispatch **one** U2 agent per page with all
   of its findings, never two agents writing the same file in parallel.
4. Route each page to its prompt by the page's effective action and type (see
   the U2 table).

## The `action` taxonomy and the `mode` cap

Each finding carries an `action`: `touch-up` (patch in place), `overhaul`
(restructure + rewrite), `create` (author fresh), `leave` (no work), `skip`
(human veto). The global `mode` is only a cap over those per-page actions:

- `auto` (default) — honour each finding's `action`.
- `touch-up` — clamp every action down to at most `touch-up`: never restructure
  or rewrite, only patch in place. Safe for a well-tended repo.
- `overhaul` — raise every actionable finding up to `overhaul`.

`leave` and `skip` are always respected; greenfield areas keep `create` under
every mode. When `mode` is not given and no report was passed, surface the
`check-docs` recommendation and confirm before writing.

## Workflow

After obtaining the work-list, run five waves. Generation uses a capable model;
self-verify and voice use a cheap model. One agent per page caps tail latency.

### U1 — Scaffold if missing (orchestrator, deterministic)

If the repo has no `docs/source/` skeleton, lay one down from `assets/`:

- Copy `assets/docs-source-skeleton/` to `docs/source/`.
- Merge the build targets and dependencies (see *Merging safely* below).
- Drop the verbatim meta-layer (`assets/meta/voice.md`,
  `documentation_guide.md`, `writing_documentation.md`) into
  `docs/source/contributing/`.
- Create `assets/tests-docs-harness/` at `tests/docs/`.
- **Resolve every `EDIT:` marker** the skeleton carries: project name, author,
  the distribution name for the version lookup (`DIST_NAME` in `conf.py`), the
  package name in `reference/python-api.md`, and the `sys.path`/`src/` line if
  the repo is not src-layout. A scaffold with unresolved markers does not
  count as done — `make docs-strict` must pass before U2 starts.

What U1 does depends on what is already there:

| Existing setup | U1 behaviour |
|----------------|--------------|
| nothing | full scaffold as above |
| copier-scaffolded with this structure | detect; skip or reconcile, never overwrite |
| MkDocs (`mkdocs.yml`) | confirm with the human before converting; on overhaul, migrate the `nav` into the new toctrees and retire `mkdocs.yml` in the same run — never leave two doc systems side by side |
| plain Sphinx (`conf.py` without MyST) | do not blind-copy the skeleton over it; reconcile `conf.py` (add `myst_parser`, mermaid, theme as needed) so existing `.rst` keeps building while new MyST pages join |
| target structure already present | skip; an `overhaul` action restructures existing content into `docs/source/` |

**Merging safely.** Both merges must be idempotent and non-clobbering:

- Makefile: the asset's header comment is the sentinel — if it is already
  present, skip. Prefer copying the asset to `docs.mk` and adding one
  `include docs.mk` line. If the Makefile already defines `docs`, `test-docs`,
  or another colliding target, stop and report instead of overwriting.
- **No Makefile at all → create one** whose sole content is the
  `include docs.mk` line. The docs workflow is make-driven by design; an
  existing tox/nox/just setup is left untouched beside it, never migrated.
- `pyproject.toml`: add the `docs` dependency group only if no `docs` group or
  extra exists; otherwise reconcile missing packages into the existing one.
- The targets are opinionated, not detected: `uv` is the package manager
  (`uv sync --group docs`, `RUN ?= uv run`) and `src/` is the layout
  (`docs-live` watches `src/`). If the repo evidently uses another package
  manager (a `poetry.lock` and no `uv.lock`), stop and report instead of
  scaffolding targets that cannot run.

### U2 — Patch / generate / migrate (parallel, one agent per page, capable model)

Per the page's effective action, dispatch the matching prompt:

| Action · page type | Prompt |
|--------------------|--------|
| `touch-up` — any existing page, patch in place | `prompts/touch-up.md` |
| `create`/`overhaul` — concept / architecture (mermaid lives here) | `prompts/generate-explanation.md` |
| `create`/`overhaul` — how-to (getting_started, code_style, testing, ci_cd, git_workflow, guides, operations) | `prompts/generate-howto.md` |
| `create`/`overhaul` — reference (glossary, FAQ, rest-api, python-api) | `prompts/generate-reference.md` |
| `overhaul` — reshape an existing legacy page into its new home | `prompts/migrate-legacy.md` |

A `touch-up` page receives *all* of its findings in one dispatch and is edited
minimally — structure and untouched prose survive verbatim. Generation and
migration write the page whole. Ground every claim in a `file:line` reference.
Add mermaid for architecture and key workflows. Label designed-but-unbuilt
behaviour with a self-contained `{caution}` admonition (what is unbuilt and
why — no ledger file). **Greenfield skips ADR authoring** — create only an
`adr/index.md` placeholder; rationale for past decisions is not derivable from
code. Legacy ADRs are migrated verbatim (fix links and naming only — never
fact-check historical rationale against current source).

### U3 — Self-verify (parallel, cheap model, one per changed page)

With `prompts/self-verify.md`, fact-check the prose *this run wrote* against
current source. Pass each agent the page's change list (`$CHANGES`, from the
U2 agent's output; `full-page` for pages wholly authored this run) so a
touched-up page is verified only where it changed. Unverifiable claims get a
`{caution}` appended — existing prose is never deleted. This checks new
content; it does not re-audit the repository.

### U4 — Voice (parallel, cheap model, one per page)

With `prompts/voice-apply.md`, apply the `voice.md` rules. For a `touch-up`
action, report findings rather than auto-applying them.

### U5 — Wire and verify (orchestrator)

With `prompts/synthesizer.md`: wire every page into a `toctree`; generate or
refresh the `tests/docs/` tripwires that pin documented symbols, enum values,
and defaults; run `make docs-strict` and `make test-docs`; fix failures caused
by this run's pages (at most three fix-and-rebuild rounds — what still fails
goes in the report, not into a fourth round); leave pre-existing warnings in
untouched pages alone and list them for follow-up; optionally run the separate,
network-dependent `make docs-linkcheck`; and emit a report listing everything
created, migrated, corrected, and flagged for human follow-up.

### Filling the prompts

| Placeholder | Used by | Source |
|-------------|---------|--------|
| `$PROJECT_CONTEXT` | all U2 prompts, synthesizer | report's `## Project context` (report mode) or the in-conversation `check-docs` discovery |
| `$FINDINGS` / `$FINDING` | touch-up, migrate-legacy | the report entries targeting the page, verbatim |
| `$TARGET_PATH`, `$PAGE_TYPE` / `$TARGET_TYPE` | generate-*, migrate-legacy | the finding's **Target** line |
| `$LEGACY_PATH` | migrate-legacy | the finding's **Location** |
| `$PAGE_PATH` | touch-up, self-verify, voice-apply | the page on disk |
| `$CHANGES` | self-verify | the U2 agent's change list, or `full-page` |
| `$CITATIONS` | self-verify | the `file:line` references the U2 agent emitted |
| `$FINDING_ACTION` | voice-apply | the page's effective action after the cap |
| `$CHANGED_PAGES`, `$DRIFT_LISTS`, `$VOICE_REPORTS` | synthesizer | collected U2 page list, U3 drift lists, U4 voice reports |

## Non-goals

- Never fabricate ADR rationale.
- Never impose hexagonal layers on a non-hexagonal repo (detect and adapt).
- Never present an unverifiable claim as fact — flag with `{caution}`.
- Never silently truncate — the U5 report enumerates everything touched.

See `README.md` for the human workflow and `assets/meta/` for the canonical
voice and documentation conventions.
