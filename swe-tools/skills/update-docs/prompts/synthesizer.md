PROJECT_CONTEXT: $PROJECT_CONTEXT
CHANGED_PAGES: $CHANGED_PAGES    (list of all pages written, migrated, or corrected in this run)
DRIFT_LISTS: $DRIFT_LISTS        (concatenated drift list output from all U3 self-verify agents)
VOICE_REPORTS: $VOICE_REPORTS    (concatenated voice output from all U4 voice-apply agents)

YOUR ROLE: Wave U5 orchestrator. Wire, verify, and report. You CAN write and
edit files. Work through the steps below in order; do not skip a step because
a later one seems more urgent.

---

## Step 1 — Wire pages into toctrees

For each page in `$CHANGED_PAGES`:

1. Identify the section index file that owns the page's directory
   (e.g. a page at `docs/source/concepts/caching.md` belongs in
   `docs/source/concepts/index.md`).
2. Check whether the page's docname — its path relative to the directory
   of the index file whose toctree lists it, without the `.md` suffix
   (e.g. `caching` for a sibling page, `internals/caching` for a page one
   level down) — already appears in a `toctree` directive in that index.
   If it does not, add it.
3. Write the updated index file.

A page missing from every toctree causes `make docs-strict` to fail with a
"document not included in any toctree" warning (promoted to an error by `-W`).
Wire every page before running the build.

---

## Step 2 — Generate or refresh the test tripwires

Read `tests/docs/test_doc_claims.py` (the harness template lives at
`assets/tests-docs-harness/test_doc_claims.py` if no project-level file
exists yet).

For each page in `$CHANGED_PAGES`, identify the claims that can be mechanically
pinned:

- **Exported symbols** — any class, function, or constant that the documentation
  names as part of the public API. Add a test that imports it and confirms it
  is importable.
- **Enum values** — any enum member documented by name. Add a test that compares
  the value to the documented name.
- **Defaults** — any setting or parameter default documented with a concrete
  value. Add a test that instantiates the object (or reads the class attribute)
  and asserts the value.

Follow the harness template's conventions:
- Every test function carries a one-line docstring stating what is being
  checked and why.
- No test may import from the docs tree; it must import from the production
  package.
- Do not add tests for claims that are already covered by existing tests.

Write the updated `tests/docs/test_doc_claims.py`.

---

## Step 3 — Run the build and tests

Run in order:

```bash
make docs-strict
```

If `make docs-strict` fails:

- Parse the warnings/errors for the page(s) at fault.
- Fix warnings only in pages that were touched this run (`$CHANGED_PAGES`
  and the index files edited in Step 1): broken `{doc}` roles, missing
  toctree entries, malformed directives.
- Warnings in pages NOT touched this run are out of scope — never "fix"
  them, as that would re-audit and rewrite pages outside this run. List
  them in the report under "Flagged for human follow-up" instead.
- Rerun after fixing, up to a maximum of **3** fix-and-rebuild iterations.
  If failures remain after the third rebuild, stop fixing and record the
  remaining failures in the report under "Flagged for human follow-up".

Then run:

```bash
make test-docs
```

If `make test-docs` fails:

- A failing test means a claim in `tests/docs/test_doc_claims.py` is wrong.
  Check whether the documentation or the test assertion is incorrect.
- If the documentation is wrong (code changed since U3 ran): correct the page
  and update the test.
- If the test assertion is wrong (the test was mis-authored): fix the test.
- Rerun after fixing, up to a maximum of **3** fix-and-rerun iterations.
  If failures remain after the third rerun, stop fixing and record the
  remaining failures in the report under "Flagged for human follow-up".

Do not silence failures by weakening assertions or removing tests.

Finally, as a separate optional step, run:

```bash
make docs-linkcheck
```

Linkcheck needs network access. If it fails or times out (offline, CI
without egress), note that in the report — including which links could not
be checked, if available — and continue; a linkcheck failure does not make
the run failed. Fix genuinely broken links only in pages touched this run;
broken links in untouched pages go under "Flagged for human follow-up".

---

## Step 4 — Emit the final report

Collect the following inputs:
- The list of all pages written, migrated, or corrected (`$CHANGED_PAGES`).
- All drift entries from `$DRIFT_LISTS`.
- All voice violations (touch-up mode) or change summaries from `$VOICE_REPORTS`.

Emit the report to standard output (not to disk) under these headings:

### Created
List each newly authored page: path and one-line description.

### Migrated
List each legacy page migrated: source path → target path, and the quarantine
note summary (what was dropped and why).

### Corrected
List each page that had drift or voice changes applied: path and a summary of
what changed.

### Toctree changes
List each index file edited and which docnames were added.

### Test tripwires
List each test added or updated in `tests/docs/test_doc_claims.py`, with the
claim it pins.

### Build result
State whether `make docs-strict` and `make test-docs` passed, and the
outcome of the optional `make docs-linkcheck` step (passed, failed, or
skipped/timed out for lack of network). If any warnings remain after
fixing, list them here.

### Cautions added
List every `{caution}` admonition added during this run (by the generate,
migrate, and self-verify agents): page path and the admonition's first
sentence.

### Flagged for human follow-up
List every item that requires human judgment:
- Unsalvageable legacy claims (from migrate-legacy quarantine notes).
- Unverifiable claims flagged with `{caution}` admonitions (from drift
  lists).
- Pre-existing drift reported-not-fixed by self-verify agents (drift list
  entries tagged "pre-existing — reported, not fixed").
- Touch-up voice violations that were reported but not auto-applied
  (from `$VOICE_REPORTS`).
- Build or test failures remaining after the 3-iteration fix cap, and
  warnings or broken links in pages not touched this run.

Each entry: the page path, the flagged sentence or section, and the reason it
was not resolved automatically.

---

## Non-goals

- Do not re-audit pages that were not changed in this run. This includes
  build warnings and broken links found in such pages: they are reported
  under "Flagged for human follow-up", never fixed by this wave.
- Do not remove or weaken existing tests.
- Do not modify `assets/` files — those are the skill's canonical source.
- Do not fabricate build output; run the commands and report actual results.
