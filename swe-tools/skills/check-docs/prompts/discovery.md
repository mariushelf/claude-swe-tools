SCOPE: $SCOPE
ARGUMENTS: $ARGUMENTS  (parsed for `scope:` and `out:` overrides)

YOUR ROLE: Discovery scout (Wave A). Survey the repository — code first, docs
second — and produce three outputs that every later agent in this run reuses.
Read-only; write nothing.

**Scoped runs.** When a `scope:` argument is present, survey the whole repo
only enough to build $PROJECT_CONTEXT (orientation), but restrict the
site-map, the per-page action estimates, and the area lists for the lens
fan-out to the scoped subtree. Frame the mode recommendation as a
recommendation for that subtree only, not for the repository as a whole.

---

## Step 1 — Package layout

Inspect `pyproject.toml` (or `setup.cfg`, `setup.py`), the source tree, and
`Makefile` / `tox.ini` / `noxfile.py` if present. Determine:

- Source layout: `src/<pkg>/` vs flat `<pkg>/`.
- Whether the repo is copier-scaffolded (look for a `.copier-answers.yml` or
  `template/` with a `copier.yaml`).
- Layering pattern: hexagonal (ports+adapters), MVC, layered, monolith, or
  other. Identify key layer packages (`domain`, `services`, `adapters`, `api`
  or their equivalents).
- Test layout: `tests/` vs `src/<pkg>/tests/`; presence of `tests/docs/`.
- CI configuration files (`.github/`, `azure-pipelines.yml`, etc.) and whether
  a `make docs` or `make docs-strict` target exists.

## Step 2 — Existing documentation

Locate every doc artifact under `docs/`, `README.md`, and any top-level
`.rst`/`.md` files. For each, record:

- Current path.
- Diátaxis type: explanation (concept/architecture), how-to, reference,
  tutorial, decision record (ADR), or meta.
- Primary audience: orientation (any reader), users, operators, maintainers.
- Whether it lives inside `docs/source/` (rendered) or outside (dev artifact).
- Proposed target home in the `docs/source/<audience>/<type>/` model.

Classify the overall documentation state as one of:
- **none** — no substantive docs beyond a short README.
- **legacy-MD** — markdown docs exist but are not Sphinx-rendered.
- **legacy-Sphinx** — Sphinx docs (`.rst` or non-MyST) outside the target
  model.
- **MkDocs** — MkDocs-served docs.
- **target** — already `docs/source/` with MyST + Sphinx.

## Step 3 — Public API surface

Identify the public surface an audit must cover:

- Exported symbols: scan `__init__.py` files for `__all__` or unguarded
  imports; note the module path and whether a doc page exists.
- FastAPI/Flask/Starlette routes: find `@app.get`, `@router.post`, etc.;
  record path, method, and whether any reference doc covers them.
- CLI entrypoints declared in `pyproject.toml` `[project.scripts]`.
- Settings / environment variables: Pydantic `BaseSettings` subclasses, or
  `os.environ` reads; note whether a settings reference page exists.
- Architecture subsystems (ports, adapters, services, domain entities) that
  have no corresponding concept or architecture page.

## Step 4 — Site-map

Emit a table: pages that *should* exist in the target model vs. what currently
exists. Columns: `target-path | current-path (or "missing") | action-estimate`.
Use the action taxonomy: `touch-up`, `overhaul`, `create`, `leave`, `skip`.

## Step 5 — Mode recommendation

Based on the gap between current state and target model, recommend one of:

- **auto** — honor each finding's auto-estimated action. This is the normal
  path, not a verdict that the docs are broadly correct.
- **touch-up** — clamp every action down to at most touch-up: never
  restructure or rewrite, only patch in place.
- **overhaul** — raise every actionable finding up to overhaul.

Give one sentence of reasoning.

---

## Output

Deliver three blocks in this order. Keep total output under 900 words; the
site-map table is exempt from this cap. When the existing tree exceeds ~30
pages, aggregate site-map rows per-directory rather than listing every page.

### $PROJECT_CONTEXT

A 3–5 sentence paragraph every later agent prompt receives verbatim. Include:
language + key frameworks, primary purpose, runtime model (CLI / service /
library / batch), documentation state (one of the five classifications above),
whether the repo is hexagonal, and whether `docs/source/` exists.

### Site-map

The table from Step 4. Add a column `diátaxis-type` and `audience`.

### Mode recommendation

```
mode: <auto|touch-up|overhaul>
reason: <one sentence>
```
