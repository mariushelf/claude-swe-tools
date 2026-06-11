# check-docs

A read-only audit of a Python repository's documentation against its source
code. It produces a single prioritised `DOC_AUDIT.md` and **never touches a
documentation page** — the report (by default under the unrendered
`docs/reviews/`) is the only file it creates. It is the observe half of a
pair; the write half is `update-docs`.

## What it does

`check-docs` surveys the repository, then fans out cheap parallel agents across
four lenses — coverage, drift, structure, voice — and merges their findings into
one report:

- **coverage** — public surface, endpoints, settings, and subsystems with no docs.
- **drift** — doc claims contradicted by the current source (with `file:line`).
- **structure** — misplaced pages, missing `toctree` entries, wrong Diátaxis or
  audience placement, content rendered that should not be.
- **voice** — violations of the documentation voice rules.

## Running it

```
/check-docs
/check-docs scope:docs/source/architecture
/check-docs out:/tmp/audit.md
```

- `scope:` limits the audit to a path. Default: `docs/` plus the package's public
  surface.
- `out:` sets the report path. Default: `docs/reviews/<date>-doc-audit/DOC_AUDIT.md`.

## The report is the contract

The output is the single artefact and it is self-documenting — it opens with a
"How to use this report" preamble. There is no separate machine-readable
manifest: the consumer is `update-docs`, which reads markdown directly, so a
parallel YAML representation would only add a sync burden for no reader that
needs it.

Each finding is a markdown entry whose heading carries an auto-estimated
`action`:

```markdown
### COV-001 · coverage · severity: high · action: overhaul
**Location:** `src/pkg/clustering.py:42`
**Target:** `concepts/clustering.md` (concept)
**Evidence:** `cluster_records()` is public and undocumented; no page under `concepts/`.
**Fix:** create a concept page for clustering, link to the ADR.
```

The **Target** line names the page `update-docs` will write (and its type) —
edit it to redirect the work. The report also embeds the project context, so a
curated report is self-sufficient: `update-docs report:` needs nothing from
the original conversation.

`action` is one of:

| action | meaning |
|--------|---------|
| `touch-up` | patch/correct in place; keep structure and prose |
| `overhaul` | restructure into `docs/source/`, rewrite to voice, regenerate |
| `create` | greenfield gap; author fresh from code |
| `leave` | fine as-is, or human-only work (e.g. an ADR gap); recorded, never acted on |
| `skip` | veto; do not touch even though a fix was suggested |

## The three ways to use the report

1. **Read it.** The prioritised findings are a worklist a human can act on
   directly.
2. **Curate it, then hand it off.** Edit the `action` in any finding's heading —
   set `skip` to veto, `leave` if it is actually fine, raise to `overhaul` for a
   full rewrite — then run `update-docs report:<path-to-DOC_AUDIT.md>`.
   `update-docs` trusts the curated report completely and does not re-explore.
3. **Let `update-docs` call it.** Running `update-docs` with no report invokes
   `check-docs` itself; the findings pass in-conversation and never hit disk.

Editing the report between the two skills is the human-in-the-loop point:
observation, human judgement, and mutation stay three separable stages.

As a CI or pre-PR gate, consume the report mechanically: fail the job when the
summary table counts any high-severity finding (or whatever threshold the
project sets).

## When not to use it

- To make the fixes — use `update-docs`.
- To review code rather than docs — use `deep-code-review`.
- For a single-file proofread.

See `SKILL.md` for the wave-by-wave method and `../update-docs/assets/meta/` for
the canonical voice and documentation conventions the audit measures against.
