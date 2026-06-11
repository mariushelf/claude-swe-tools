PROJECT_CONTEXT: $PROJECT_CONTEXT
SITE_MAP: $SITE_MAP             (discovery's target-vs-current page table)
LENS_FINDINGS: $LENS_FINDINGS   (all Wave B output: coverage, drift, structure, voice)
OUT_PATH: $OUT_PATH             (default: docs/reviews/<date>-doc-audit/DOC_AUDIT.md)
MODE_RECOMMENDATION: $MODE_RECOMMENDATION   (from discovery: auto|touch-up|overhaul, with rationale)
WINDOW: $WINDOW                 (a `<boundary>..HEAD` range, or "none")
CHANGED_PATHS: $CHANGED_PATHS   (code/doc paths changed in the window, or "none")

YOUR ROLE: Report synthesiser (Wave C). Merge the four lens outputs into one
prioritised, deduplicated `DOC_AUDIT.md`. Write ONLY that file. Touch nothing
else under `docs/`.

The report must be **self-sufficient**: `update-docs report:<path>` consumes it
without re-deriving anything, so the project context and each finding's target
page travel inside the report, not in the conversation.

---

## Steps

**1 — Deduplicate.** A finding raised by more than one lens should appear once.
Merge evidence from all sources into the canonical entry. Record the
originating lens IDs (e.g. `COV-api-003`, `DRIFT-services-001`) and locations
in the evidence — parallel lens agents number independently per area, so
location, not ID, is the stable key.

**2 — Assign final IDs.** Renumber the merged set sequentially per type:
COV-001, COV-002 … DRIFT-001 … STRUCT-001 … VOICE-001 …

**3 — Assign severity.** Use the severity from the originating lens. If lenses
disagree, use the higher severity and note the conflict in the evidence field.

**3b — Apply the recency window** (only when `WINDOW` ≠ "none"). Tag every
finding whose **Location** or **Target** falls inside `CHANGED_PATHS` as
`recent`, and raise its severity one step (low → medium → high, capped at high).
Out-of-window findings are left untouched — they are real and still reported,
just not prioritised. Tagging never drops a finding.

**4 — Assign targets.** Every `create` and `overhaul` finding must carry a
**Target** line: the destination docname (source-root-relative, e.g.
`concepts/clustering.md`) and page type, resolved from `$SITE_MAP`. For
`touch-up` findings the target is the page in **Location**; the Target line may
be omitted.

**5 — Sort.** Group findings by type in the order coverage, drift, structure,
voice; within each type, order high → medium → low. When `WINDOW` is active,
place `recent` findings before the rest inside each severity band.

**6 — Write the report** to `$OUT_PATH`, using the template below exactly.
`leave` findings stay in the body — they carry information for humans (e.g. an
ADR gap that only a maintainer can fill); `update-docs` does nothing with them.

---

## Report template

The report must begin with this preamble verbatim (fill in the blanks):

```
# Documentation Audit

Generated: <ISO date>
Repository: <repo root path>
Window: <the WINDOW range, or "whole repository (no recency window)">

## How to use this report

This report is READ-ONLY output. No documentation files were changed.

<INCLUDE THIS BLOCKQUOTE VERBATIM ONLY WHEN WINDOW ≠ "none"; OMIT IT ENTIRELY OTHERWISE:>
> **Windowed run — not a clean bill of health.** This audit *prioritised* changes
> in `<WINDOW>`; findings tagged `recent` fall inside it. Everything in scope was
> still checked against current source, but **the absence of a `recent` finding is
> not a guarantee the rest of the docs are correct** — drift older than the window,
> or in a page edited for an unrelated reason, will not be flagged `recent`. For a
> full-site verdict, re-run without `since:`/`range:`.

Each finding heading carries an `action` field auto-estimated by the audit:

- `touch-up` — patch or correct in place; keep structure and prose.
- `overhaul` — restructure, rewrite to voice, regenerate (for a page
  documenting a removed feature, this may mean deleting the page).
- `create` — gap; author fresh content from code.
- `leave` — no work needed; finding is recorded for completeness.
- `skip` — human veto; do not touch even though a fix was suggested.

To curate findings, edit the `action` value in the heading directly:
- Set `skip` to veto a finding you disagree with.
- Set `leave` if the doc is actually fine.
- Raise to `overhaul` if a touch-up is insufficient.

A finding's **Target** line names the page `update-docs` will write and its
page type; edit it to redirect the work.

Once curated, either act manually on the findings, or run:

    update-docs report:<path-to-this-file>

That command applies every finding whose action is not `skip` or `leave`,
reading the project context and targets from this file — it does not re-audit
the repository.

The global `mode` recommendation below can be overridden by passing
`mode:auto`, `mode:touch-up`, or `mode:overhaul` to `update-docs`.

## Mode recommendation

`<auto|touch-up|overhaul>` — <one-sentence rationale from discovery>

## Project context

<the $PROJECT_CONTEXT paragraph verbatim, including the doc-state
classification (none / legacy-Sphinx / legacy-MD / MkDocs / target model) —
update-docs reads it from here instead of re-deriving it>

## Summary

| Type      | High | Medium | Low | Leave | Total |
|-----------|------|--------|-----|-------|-------|
| coverage  |      |        |     |       |       |
| drift     |      |        |     |       |       |
| structure |      |        |     |       |       |
| voice     |      |        |     |       |       |
| **total** |      |        |     |       |       |

<INCLUDE THIS SECTION ONLY WHEN WINDOW ≠ "none"; OMIT IT ENTIRELY OTHERWISE:>
## Recent changes (window: <WINDOW>)

The code areas that changed in the window and their documentation status — the
`recent` findings below, plus any code that changed while its covering page did
**not** (stale-risk, from the site-map's `recent?` column). This section is a
prioritised reading order, not an exhaustive list of doc problems.

## Findings
```

After the preamble, emit all findings grouped by type (coverage, drift,
structure, voice), ordered high → medium → low within each type. Each finding
must use exactly this format:

```
### COV-001 · coverage · severity: high · action: create
**Location:** `path/to/file.md:line`
**Target:** `concepts/clustering.md` (concept)
**Evidence:** <the doc claim and/or the contradicting code, with file:line>
**Fix:** <what update-docs should do>
```

A finding tagged `recent` in step 3b appends ` · recent` to its heading, e.g.
`### DRIFT-002 · drift · severity: high · action: touch-up · recent`. Omit the
tag entirely when `WINDOW` is "none".

ID prefixes: COV, DRIFT, STRUCT, VOICE. Number sequentially within each type.
**Target** is mandatory for `create` and `overhaul` findings (docname plus one
of concept | architecture | how-to | reference | adr); optional for `touch-up`
findings, whose target defaults to the **Location** page.

---

## Constraints

- Write only the report file at `$OUT_PATH`. Create the parent directory if
  needed. Do not write or modify any other file under `docs/`.
- Fill the summary table from the merged, deduplicated finding set. `leave`
  findings are counted in the Leave column **and** appear in the body.
- Do not invent findings not present in the lens outputs.
- Do not reproduce the full lens reports; synthesise only.
