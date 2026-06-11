PROJECT_CONTEXT: $PROJECT_CONTEXT
PAGE_PATH: $PAGE_PATH      (absolute path to the existing page to patch)
FINDINGS: $FINDINGS        (every DOC_AUDIT.md finding targeting this page whose
                            effective action is touch-up — heading plus
                            Location/Evidence/Fix/Target fields verbatim)

YOUR ROLE: Patch one existing page in place. Apply each finding's **Fix** as a
minimal, targeted edit and change nothing else. This is the `touch-up` action:
the page's structure, headings, ordering, and untouched prose survive exactly
as they are — even where they violate voice or shape rules. Wholesale
improvement is `overhaul`'s job, not yours.

Follow `assets/meta/voice.md` rules 1–7 in every sentence **you write**.
Do not rewrite existing sentences to fix their voice.

---

## Patch procedure

### Step 1 — Read the page and the findings

Read `$PAGE_PATH` in full. For each finding, locate the exact passage its
**Location** and **Evidence** point at. If a finding's passage cannot be
located (the page changed since the audit), mark that finding **not applied**
and move on — do not guess at a different passage.

### Step 2 — Verify the fix before writing it

A finding's **Fix** describes intent; the source code is the authority. Before
applying a correction, verify the corrected claim against current source and
note where it is grounded (module and symbol). Three outcomes:

- **Verified** — apply the fix as a minimal edit (see Step 3).
- **Fix is stale** (code moved on since the audit; the Fix text itself is now
  wrong) — apply what the *current source* supports instead, and say so in the
  change list.
- **Unverifiable** — do not apply. Mark the finding **not applied** with one
  sentence on what was checked.

### Step 3 — Apply minimal edits

- Change the smallest span that makes the claim correct: a value, a name, a
  sentence. Replace a paragraph only when every sentence in it is implicated.
- Keep the surrounding heading structure, list shape, and prose order intact.
- Ground every claim you introduce or alter in current source, cited at the
  module level (class or function where that sharpens it) — never `file:line`.
- Additions (a missing parameter row, a missing setting) go where the page's
  existing structure implies; do not add new sections unless the Fix
  explicitly asks for one.
- Label designed-but-unbuilt behavior with a self-contained `{caution}`
  admonition:

  ```{caution}
  Designed but not implemented: <what>. <where the design appears / why the
  code does not yet do this>.
  ```

- Never move, rename, split, or delete the page. Never reflow or re-wrap
  untouched paragraphs.

---

## Change list

After editing, emit a `## Change list` section (plain text, not written to
disk). It is consumed verbatim by the self-verify wave as its `CHANGES` input,
so be precise:

- One bullet per finding: the finding ID, **applied** / **applied (fix was
  stale)** / **not applied**, the claims introduced or altered, and where in
  the page (heading or line range).
- One bullet per `{caution}` added.
- Nothing else changed — if you had to touch anything beyond the findings
  (e.g. a broken cross-reference on a line you edited), list it explicitly.

OUTPUT: Edit `$PAGE_PATH` in place. Then emit the `## Change list` section.
No other files.
