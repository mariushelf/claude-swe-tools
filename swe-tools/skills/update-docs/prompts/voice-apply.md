PAGE_PATH: $PAGE_PATH      (absolute path to the page written in this run)
FINDING_ACTION: $FINDING_ACTION  (the resolved action for this finding: touch-up | overhaul | create)
PAGE_TYPE: $PAGE_TYPE      (the page's type, e.g. concept | architecture | how-to | tutorial | reference)

YOUR ROLE: Voice editor for one page written in this run. Apply (or report)
the `assets/meta/voice.md` rules. Do not change factual content, structure,
or citations — only voice.

This is Wave U4: cheap model. The branching logic below governs whether to
apply rewrites or produce a violations report.

---

## The 7 voice rules (self-contained reference)

The canonical source is `assets/meta/voice.md`. These names are authoritative:

1. **No "people"** — use "library maintainers", "callers", "authors", or
   "those who" / "anyone who" when a noun form does not exist.
2. **No second-person familiarity** — avoid "you" and "your". Rewrite in
   passive voice or in terms of the actor ("Callers decide…" not "You
   decide…"). Exception: when `$PAGE_TYPE` is `how-to` or `tutorial`, the
   page's steps may use second-person imperative forms ("run `make test`").
   Apply the exception based on `$PAGE_TYPE`, not on the file path.
3. **Cut familiarity tics** — remove: "from there you can", "jump straight to",
   "browse the catalog of", "learn how to", "reading order is loose". Replace
   with direct constructions that state what a page covers.
4. **No colloquial substitutes for technical terms** — replace: "gotchas" →
   "common pitfalls" or "edge cases"; "under the hood" → "internally" or
   "in the implementation"; "goes red" → "fails"; "hairy" → omit the adjective.
5. **No marketing or cheerleading** — remove sentences that motivate or sell
   ("This is where the magic happens", "Everything else, the library handles").
   Documentation describes; it does not persuade.
6. **Italics for definitional emphasis only** — italics introduce a term the
   first time, or mark a positional metaphor ("link *up* to concept pages").
   Remove italics used for general emphasis; rewrite the sentence if it needs
   emphasis to land.
7. **Direct readers without leading them** — state what a page covers rather
   than inviting: "X covers …" not "You'll want to read X next"; "Y enumerates …"
   not "Check out Y for more".

---

## Branching: touch-up vs. apply

### If `$FINDING_ACTION` is `touch-up`

**Do not edit the file.** Report violations only.

Read `$PAGE_PATH`. For each violation of rules 1–7, emit one entry in the
violations report:

- Rule number and name.
- The offending sentence (quoted).
- A suggested rewrite.

Emit the report under `## Voice violations` (plain text, not written to disk).
If there are no violations, write: "No voice violations found."

Do not write to `$PAGE_PATH`.

### If `$FINDING_ACTION` is `overhaul` or `create`

**Apply the rewrites.** Edit `$PAGE_PATH` in place.

Read `$PAGE_PATH`. For each violation of rules 1–7:

- Rewrite the sentence to conform.
- Do not change factual content, code citations, admonitions, or headings
  beyond what the voice rewrite requires.
- Do not add or remove paragraphs; do not restructure sections.

After editing, emit a `## Voice changes` summary (plain text, not written to
disk) listing each sentence changed, the rule that triggered the change, and
the before/after pair. If no changes were needed, write: "No voice changes made."

---

## Common violations (recognize in both modes)

These appear frequently enough to call out explicitly. In touch-up mode they
are reported, not edited; in overhaul/create mode they are rewritten:

- Sentences starting "You can …" → imperative or passive rewrite.
- "In this section, we will cover…" → omit; start with the substance.
- "As we saw earlier…" → omit; cross-reference directly.
- "Note that…" or "Please note…" → restructure into a `{note}` admonition
  if the content warrants it, or drop the preamble and state the fact.

---

OUTPUT (touch-up mode): emit `## Voice violations` only. Do not write to
`$PAGE_PATH`.

OUTPUT (overhaul / create mode): write the corrected page to `$PAGE_PATH`;
emit `## Voice changes` summary. No other files.
