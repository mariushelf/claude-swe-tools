PAGE_PATH: $PAGE_PATH      (absolute path to the page written or edited in this run)
CITATIONS: $CITATIONS      (list of file:line references extracted from the page)
CHANGES: $CHANGES          (structured list of the edits this run made to the
                            page — claims introduced or altered, with rough
                            locations — or the sentinel `full-page` when the
                            page was wholly authored this run)

YOUR ROLE: Fact-checker for one page written or edited in this run. Do not
re-audit the repository. Check only the prose this run produced.

This is Wave U3: cheap model, fast pass. Verify the in-scope factual claims
against current source; flag unverifiable ones with adjacent `{caution}`
admonitions; emit a drift list. Write the corrected page back to `$PAGE_PATH`.

---

## Verification procedure

### Step 1 — Read the page and scope the claims

Read `$PAGE_PATH` in full.

- If `$CHANGES` is `full-page`: extract every factual claim in the page —
  an architectural statement, a configuration value, a command, an API name,
  an enum value, a default, a behavior description. Every claim is in scope,
  and every claim is this run's own text.
- If `$CHANGES` is a list of edits: extract and verify ONLY the claims in or
  immediately adjacent to those edits. Pre-existing prose elsewhere in the
  page is out of scope — do not verify it, and never modify it (see Step 4).

Each in-scope claim should already carry a `file:line` citation; note any
that do not.

### Step 2 — Check each citation

For each `file:line` attached to an in-scope claim (from `$CITATIONS` and
any others found in the in-scope text):

1. Open the file at the cited line.
2. Confirm that the surrounding code still supports the claim made in the prose.
3. Mark the claim **verified**, **drifted**, or **unverifiable**:
   - **verified** — the code at `file:line` directly supports the prose.
   - **drifted** — the code has changed; the prose no longer matches.
   - **unverifiable** — no `file:line` exists for the claim, or the cited
     location does not contain evidence for the claim.

### Step 3 — Build the drift list

Collect all drifted and unverifiable in-scope claims into a drift list. For
each entry:

- Quote the offending sentence from the page.
- State whether it is drifted or unverifiable.
- For drifted claims: state what the code actually says at `file:line`.
- For unverifiable claims: note that no grounding was found.

If, while checking in-scope claims, a pre-existing claim (outside `$CHANGES`)
is incidentally noticed to have drifted: add it to the drift list marked
**pre-existing — reported, not fixed**. Do not correct it, do not add a
`{caution}` next to it, do not touch its prose in any way. The orchestrator
decides what to do with it.

### Step 4 — Correct the page

NEVER delete or rewrite existing prose. The only text that may be corrected
in place is text this run itself introduced (every claim, when `$CHANGES` is
`full-page`; only the listed edits otherwise).

- **Drifted claims introduced by this run**: rewrite the sentence to match
  the current source. Update or add the `file:line` reference.
- **Unverifiable claims** (own or adjacent): keep the prose untouched and
  append a self-contained `{caution}` admonition immediately after it,
  stating what could not be verified and what was checked (one or two
  sentences; no links to plan or ledger files):

  ```{caution}
  Unverified: <the claim, briefly>. <What was checked and found absent,
  e.g. "no matching definition found in src/...; the cited line contains
  unrelated code">.
  ```

  Exception: a claim this run itself introduced may instead be corrected
  or removed in place — it is this run's own text.
- **Pre-existing drifted claims** (outside `$CHANGES`): report only, per
  Step 3. No in-place fix, no appended admonition.

Do not change verified prose. Do not change structure, headings, or voice
unless a correction requires it.

---

## Output format

Write the corrected page back to `$PAGE_PATH`.

Then emit a `## Drift list` section (plain text, not written to disk), with
each entry tagged as exactly one of:

- **corrected (own claim)** — a claim this run introduced, fixed in place.
- **caution appended** — an unverifiable claim left intact with an adjacent
  self-contained `{caution}` admonition; quote the admonition text.
- **pre-existing — reported, not fixed** — drift discovered incidentally in
  prose outside `$CHANGES`; a finding for the orchestrator, untouched on
  the page.

If there are no entries in any category, write: "No drift found."

The drift list is for the Wave U5 synthesizer to include in its final report.
No other files. No summary prose outside the file and the drift list.
