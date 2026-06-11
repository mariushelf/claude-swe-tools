PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE          (areas assigned to this agent by the orchestrator)
SITE_MAP: $SITE_MAP    (discovery's table of target pages vs. current pages)
AREA_ID: $AREA_ID      (short slug for this agent's area, e.g. `api`)

YOUR ROLE: Coverage auditor (Wave B). Find public surface that lacks any
documentation. Read-only; emit findings only — no fixes, no file writes.

---

## What to check

Work through the SCOPE systematically. For each item below, confirm whether a
doc page covers it. A page counts as coverage if it is reachable in the repo's
*actual* published docs tree, as classified in PROJECT_CONTEXT:

- **target** model — reachable from a `toctree` under `docs/source/`.
- **MkDocs** — listed in the `mkdocs.yml` nav.
- **legacy-Sphinx** — reachable from its existing root `toctree`.
- **legacy-MD** — any tracked markdown file under `docs/`.

A README or inline comment still does not count. Whether a page sits in the
*right* tree or section is the structure lens's concern, not coverage's — do
not emit gaps for material that is documented but misplaced.

**Exported symbols**
Scan `__init__.py` files in SCOPE for `__all__` lists and for names that are
imported at the package level without a leading underscore. For each:
- Is there a reference or API page that documents it?
- Is there a concept or architecture page that explains when and why to use it?

**API endpoints**
Find route decorators (`@app.get`, `@router.post`, `@app.route`, etc.).
For each endpoint:
- Does a reference page list its path, method, request body, and response
  schema?
- Does an operational how-to describe a common usage pattern?

**Settings and environment variables**
Locate Pydantic `BaseSettings` subclasses and direct `os.environ` reads.
For each field:
- Is there a settings reference page that lists the name, type, default, and
  effect?

**Architecture subsystems**
Using the layering pattern from PROJECT_CONTEXT, identify services, ports,
adapters, domain entities, and key workflows. For each subsystem:
- Is there an explanation page describing its role and boundaries?
- Is there an ADR covering non-obvious design decisions? If not, emit the
  finding with `action: leave`, explicitly marked human-only: an ADR cannot
  be auto-authored — rationale is not derivable from code. Record the gap
  for maintainers; never propose `create` for an ADR.

**CLI entrypoints**
Find `[project.scripts]` in `pyproject.toml`. For each script:
- Is there a how-to or reference page covering invocation and options?

## Exclusions

Skip private symbols (leading underscore), vendored code, test helpers that are
not part of the public API, and anything the SITE_MAP marks `skip` or `leave`.

## Output

One finding per gap. Number findings `COV-$AREA_ID-NNN` (e.g. `COV-api-001`)
so parallel coverage agents cannot collide; the report synthesiser re-keys
IDs. Emit findings in this format:

```
### COV-$AREA_ID-NNN · coverage · severity: <high|medium|low> · action: <create|touch-up>
**Location:** `file:line`  (the undocumented symbol, route, setting, or class)
**Evidence:** <name or signature> is public and has no doc page covering <what is missing>.
**Fix:** Create a <type: concept|architecture|how-to|reference> page at `<path>`, or add the missing entry/section to the existing page.
```

Action choice: `create` when the page that should hold the material does not
exist; `touch-up` when the page exists but the entry or section is missing.
ADR gaps are the one exception: `action: leave`, marked human-only (see
above).

Severity guide:
- **high** — a public API, endpoint, or setting with no coverage at all.
- **medium** — a subsystem or key abstraction with no concept page.
- **low** — a secondary symbol documented in prose but not in a reference page.

Do not write to `docs/`. Do not propose wording for the missing pages. Emit
findings only; the report synthesiser will prioritise and dedup.
