PROJECT_CONTEXT: $PROJECT_CONTEXT
FINDING: $FINDING          (the DOC_AUDIT.md entry: includes legacy path, target path, target type)
LEGACY_PATH: $LEGACY_PATH  (absolute path to the legacy page being migrated)
TARGET_PATH: $TARGET_PATH  (docs/source-root-absolute destination, e.g. concepts/caching.md)
TARGET_TYPE: $TARGET_TYPE  (concept | architecture | how-to | reference | adr)

YOUR ROLE: Migrate one legacy page into its correct home and shape. Read the
legacy page, re-verify every claim against current source, reshape to the
correct page type, and write the result to `$TARGET_PATH`. Do not create any
other files.

**Exception — `$TARGET_TYPE` is `adr`:** decision records are historical
documents; their rationale describes the state of the world *when the decision
was made* and is not derivable from — nor falsifiable by — current source.
Skip Steps 2–4 entirely: copy the content essentially verbatim to
`$TARGET_PATH`, fixing only the filename convention, cross-reference syntax,
and broken links, and wire it into `adr/index.md`'s toctree (an obsolete ADR
goes under `adr/obsolete/`). Never fact-check, rewrite, or quarantine ADR
rationale. The `## Migration note` then lists only the mechanical fixes made.

Follow `assets/meta/voice.md` rules 1–7 in every sentence.
Follow `assets/meta/writing_documentation.md` for the procedural steps.
Follow `assets/meta/documentation_guide.md` for the page shape matching
`$TARGET_TYPE`.

---

## Migration procedure

### Step 1 — Read the legacy page

Read `$LEGACY_PATH` in full. List every factual claim it makes:
an architectural statement, a configuration value, a command, an API name,
a behavior description. Do not trust any of them yet.

### Step 2 — Verify each claim against current source

For each claim, locate the corresponding code or configuration and confirm
whether the claim is still accurate. Note the `file:line` for every claim
that holds. For a claim that no longer holds or cannot be confirmed, mark it
**unsalvageable**.

Do not reuse legacy prose verbatim. Even when a claim is accurate, re-derive
the sentence from the current source so that voice and precision are correct.

### Step 3 — Reshape to the target page type

Using the verified claims and their `file:line` references, author a page in
the shape prescribed by `$TARGET_TYPE` (see `assets/meta/documentation_guide.md`
and the matching `prompts/generate-*.md` for the full ingredient list).

Apply the page-shape rules for `$TARGET_TYPE` exactly as if this were a
greenfield page — salvageable legacy content is raw material, not a
structural guide. The target page is written to the standard shape; it does
not inherit the legacy structure.

### Step 4 — Quarantine unsalvageable content

After writing the page, compile a short note on what was dropped:

- For each unsalvageable claim: one sentence stating the claim, why it is
  unsalvageable (outdated, contradicted by code at `file:line`, or
  unverifiable), and whether a human should investigate.
- For claims that are future-oriented (aspiration, roadmap): convert to a
  self-contained `{caution}` admonition in the page stating inline what
  is designed but unbuilt and why (citing the evidence or its absence;
  no links to plan or ledger files), and include the item in the
  quarantine note so a human can decide whether to pursue it.

The quarantine note is **not** part of the written page. Emit it as a separate
section at the end of your output under the heading `## Migration note`.

---

## Authoring rules

- Re-verify every claim. Legacy prose is not evidence.
- Ground every retained claim in a `file:line` reference.
- Describe what the code does today, in present tense.
- Label designed-but-unbuilt behavior with a self-contained `{caution}`
  admonition that states inline what is unbuilt and why, citing the
  evidence or its absence (one or two sentences; no links to plan or
  ledger files):

  ```{caution}
  Designed but not implemented: <what>. <Where the design appears and
  why the code does not yet do this>.
  ```

- Cross-reference in-tree pages with the MyST `{doc}` role and
  source-root-absolute docnames: `` {doc}`/concepts/cache` ``.
- Never fabricate — if a claim cannot be verified, do not include it in
  the page; add it to the quarantine note instead.
- Do not preserve the legacy page's headings, order, or structure if they
  conflict with the target page shape.

OUTPUT: Write the migrated `.md` file to `$TARGET_PATH`. Then emit a
`## Migration note` section (plain text, not written to disk) listing what
was dropped and why. No other files.
