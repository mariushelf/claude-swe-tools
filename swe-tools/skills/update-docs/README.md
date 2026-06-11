# update-docs

Creates, repairs, and restructures a Python repository's documentation against
its source code, then wires and build-verifies it. It handles greenfield repos
(derive docs from code) and legacy repos (re-verify facts, restructure, rewrite
to voice). It is the write half of a pair; the read-only half is `check-docs`.

## The target structure

A Diátaxis layout organised first by audience, rendered by Sphinx + MyST, where
**only `docs/source/` is rendered** — so specs, plans, and other development
files sit beside the docs without being published.

```
docs/
  source/            # the only Sphinx-rendered tree
    index.md
    glossary.md
    concepts/        # explanation — what / why (users)
    guides/          # how-to (users)
    operations/      # how-to for operators — deploy, configure, monitor
    reference/       # exhaustive lookup, incl. generated python-api
    architecture/    # how it is built (maintainers)
      implementation/
    contributing/    # how-to for maintainers + the meta-layer
    adr/             # decision records
  reviews/           # NOT rendered — audit reports, working notes
```

The canonical voice and conventions ship in `assets/meta/` and are dropped into
`docs/source/contributing/` verbatim.

## Running it

```
/update-docs                                   # audit (via check-docs), then fix
/update-docs report:docs/reviews/2026-06-11-doc-audit/DOC_AUDIT.md
/update-docs mode:touch-up
/update-docs scope:docs/source/architecture
```

## Where the worklist comes from

`update-docs` does not start by exploring. It obtains a list of findings — each
carrying an `action` — one of two ways:

1. **`report:<path>` given** → it trusts that `DOC_AUDIT.md` completely and does
   no discovery, re-audit, or re-derivation. The curated report *is* the
   worklist. (It still grounds new prose in source and self-checks its own
   claims — that is authoring hygiene, not re-auditing.)
2. **No report** → it invokes the `check-docs` skill to produce one, then acts on
   the auto-estimated actions.

To put a human in the loop, run `check-docs` first, edit the `action` fields in
the report, then pass it here with `report:`.

## `action` and the `mode` cap

Each finding's `action` decides how invasively that one page is treated:
`touch-up` (patch in place), `overhaul` (restructure + rewrite), `create`
(author fresh), `leave` (nothing), `skip` (veto).

`mode:` is a global cap over those per-page actions — not a repo-wide judgement:

| `mode` | effect |
|--------|--------|
| `auto` (default) | honour each finding's `action` |
| `touch-up` | clamp every action down to at most `touch-up` — never restructure or rewrite, only patch in place; safe for a well-tended repo |
| `overhaul` | raise every actionable finding up to `overhaul` |

`leave` and `skip` are always respected; greenfield areas keep `create` under
every mode. With no `mode` and no report, the `check-docs` recommendation is
surfaced and confirmed before any write.

The granularity lives in the per-page `action`, so `mode` stays a single coarse
override rather than the only lever — that is what keeps the operation from being
blunt.

## What it does, in five waves

1. **Scaffold if missing** — lay down `docs/source/`, the Makefile targets, the
   docs dependency group, the meta-layer, and the `tests/docs/` harness, then
   resolve every `EDIT:` placeholder so the empty scaffold already builds. The
   merges are idempotent; a copier-scaffolded repo is detected and not
   overwritten, and an existing MkDocs or plain-Sphinx setup is reconciled, not
   buried. A repo without a Makefile gets one (just `include docs.mk`) — the
   workflow is deliberately opinionated on `uv`, `src/` layout, and `make`.
2. **Patch / generate / migrate** — patch each `touch-up` page in place
   (structure and untouched prose survive verbatim); author each
   `create`/`overhaul` page from code (and legacy content when migrating).
   Every claim is grounded in current source and cited at the module (or class)
   level. Mermaid is used for architecture
   and key workflows. Designed-but-unbuilt behaviour is labelled with a
   self-contained `{caution}`. Greenfield repos get no invented ADR rationale;
   legacy ADRs migrate verbatim.
3. **Self-verify** — fact-check the prose this run wrote against current
   source. Touched-up pages are verified only where they changed; existing
   prose is never deleted.
4. **Voice** — apply the voice rules (reported rather than auto-applied for a
   `touch-up`).
5. **Wire and verify** — register every page in a `toctree`, refresh the drift
   tripwires, run `make docs-strict` and `make test-docs` (plus the separate,
   network-dependent `make docs-linkcheck` when possible), and report
   everything created, migrated, corrected, and flagged for follow-up.

## Non-goals

- Never fabricate ADR rationale.
- Never impose a hexagonal layout on a repo that is not hexagonal.
- Never present an unverifiable claim as fact — flag it with `{caution}`.
- Never silently truncate — the final report enumerates everything touched.

See `SKILL.md` for the full method and `assets/meta/` for the canonical voice and
documentation conventions.
