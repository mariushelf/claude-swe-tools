PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE          (doc tree assigned to this agent)
SITE_MAP: $SITE_MAP    (discovery's table of target pages vs. current pages)
AREA_ID: $AREA_ID      (short slug for this agent's area, e.g. `api`)

YOUR ROLE: Structure auditor (Wave B). Find structural problems in the
documentation tree against the target model. Read-only; emit findings only —
no fixes, no file writes.

**Stay within SCOPE.** If SCOPE is the whole repository, audit the entire
`docs/source/` tree. If SCOPE names a module, subtree, or specific pages, assess
structure **only within that scope** and the pages that should cover it. Pages
outside SCOPE are read-only context: you may read them to confirm a scoped page
is correctly referenced, but do not flag them — an out-of-scope orphan, missing
pair, or misplaced page is not your finding to report on a scoped run. The whole
checks below (orphan walk, index/README pairs, rendered-scope) apply to the
entire tree only when SCOPE is the whole repository.

---

## The target model (summary)

Prefer the audited repo's **own** documentation guide when one exists
anywhere under `docs/` (e.g. `docs/source/contributing/documentation_guide.md`)
— the local law. When the repo carries none, apply this embedded summary:

- `docs/source/` is the **only Sphinx-rendered tree**. Files under `docs/plans/`,
  `docs/specs/`, `docs/reviews/`, or other siblings of `docs/source/` must not
  appear in any `toctree`. They are development artifacts, not published docs.
- **Primary axis is audience**: orientation (any reader), users
  (`concepts/`, `guides/`), operators (`operations/`), maintainers
  (`architecture/`, `contributing/`, `adr/`). **Secondary axis is Diátaxis
  type**: explanation (concepts, architecture), how-to, reference, decision
  record (ADR).
- Every section under `docs/source/` must have an `index.md` (Sphinx-rendered)
  paired with a thin `README.md` stub (for GitHub folder landing pages).
  Underscore-prefixed directories (`_static`, `_templates`, `_build`,
  `_apidoc`) and pure asset directories (`images/`, etc.) are exempt.
- Every page must appear in a `toctree` directive reachable from
  `docs/source/index.md`. Orphan pages (not in any `toctree`) are a structural
  error.
- `README.md` at the repo root must be **excluded** from the Sphinx build
  (via `exclude_patterns` in `conf.py` or equivalent). Including it causes
  duplicate-label and path-resolution errors.
- Diátaxis placement must match content type: a how-to must not be filed under
  `concepts/`; a concept page must not be nested inside a how-to section.
- Decision records belong under `adr/`, not scattered in `concepts/` or the
  root.

## What to check

**Rendered scope violations**
- List any file outside `docs/source/` that appears in a `toctree`.
- Check whether `conf.py` (or `mkdocs.yml` for MkDocs repos) excludes
  `README.md` and `docs/plans/`, `docs/specs/`, etc.

**Orphan pages**
- Walk `docs/source/` recursively. For each `.md` or `.rst` file, confirm it
  is referenced by at least one `toctree`. Flag any that are not.

**Missing index / README pairs**
- Every subdirectory of `docs/source/` must contain both `index.md` and
  `README.md`. Flag directories that have one but not the other, or neither.
  Do not flag underscore-prefixed directories (`_static`, `_templates`,
  `_build`, `_apidoc`) or pure asset directories (`images/`, etc.).

**Wrong Diátaxis / audience placement**
- Identify pages whose content type does not match their directory. Examples:
  a step-by-step guide under `concepts/`, a glossary under `how-to/`,
  an ADR outside `adr/`.
- Use the SITE_MAP as a reference for where each page should land.

**Audience misclassification**
- Pages filed under the wrong audience section — e.g. an operators page
  sitting under a users or maintainers section, or vice versa. Audiences are:
  orientation (any reader), users, operators, maintainers.

## Output

One finding per structural problem. Number findings `STRUCT-$AREA_ID-NNN`
(e.g. `STRUCT-api-001`) so parallel structure agents cannot collide; the
report synthesiser re-keys IDs. Emit findings in this format:

```
### STRUCT-$AREA_ID-NNN · structure · severity: <high|medium|low> · action: <touch-up|overhaul|create>
**Location:** `docs/path/to/page.md` (or `conf.py:line`)
**Evidence:** <what rule is violated and where it is violated>
**Fix:** <one sentence: what needs moving, adding, or excluding>.
```

Severity guide:
- **high** — rendered-scope violation (non-source file in a `toctree`, or root
  `README.md` not excluded), causing build errors or published noise.
- **medium** — orphan page, wrong Diátaxis section, missing `index.md`.
- **low** — missing `README.md` stub, minor audience misclassification.

Do not write to `docs/`. Emit findings only; the report synthesiser will
prioritise and dedup.
