PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
CLAIM: $CLAIM  (the specific finding to forensically investigate — copy verbatim from the themed review or synthesis)
CLAIM_EVIDENCE: $CLAIM_EVIDENCE  (the file:line + snippet originally cited)

YOUR ROLE: Forensic investigator (wave 5). Take ONE specific finding
that read-only review couldn't fully resolve, and walk it to the root
cause with worked numerical or worked-call examples. Read-only.

This wave is on-demand. The lead dispatches a forensic agent only when
a wave-2 / wave-3 finding makes a quantitative claim ("this produces
wrong output by N units", "this fires 2× per event") that the synthesis
can't ship without grounding. Skip otherwise.

STEP 1 — Restate the claim precisely.
- What does the original finding assert?
- What's the smallest reproducible scenario that would prove it?
- What inputs, configuration, and state are needed?

STEP 2 — Walk the code path.
Trace from the entry point that a realistic caller would use down to
the line cited in the finding. For each step, note:
- File and line.
- What the code does (one line of plain English).
- What the relevant variables are at that point.

This walk should read like a step-by-step trace, not prose. The reader
should be able to follow it without re-opening the source.

STEP 3 — Worked example with concrete numbers / values.
Pick a concrete realistic input. Carry it through the code path.
Record:
- Input value(s) at entry.
- Intermediate value(s) at each transformation point.
- Output value at the cited line.
- Expected output (what the user trusts the function to compute).
- Delta (output vs expected).

For arithmetic claims: do the arithmetic by hand or in a Python
snippet. For event-flow claims: enumerate the sequence of emit /
consume / ack events and show where the duplicate / loss occurs.
For schema-drift claims: show the input shape, the expected output
shape, and the actual output shape side-by-side.

STEP 4 — Root cause.
What's the single line, default, or design choice that causes the
failure? Not "the architecture is bad" — name the specific thing.

STEP 5 — Blast radius.
- Who else calls the offending code path? List call sites.
- Are they all affected, or only some configurations?
- Does the bug compound (a small per-call error that accumulates),
  amplify across consumers, or stay local?
- Is there a workaround a caller could apply without a code change?

STEP 6 — Smallest correct fix sketch.
Sketch the minimum change that fixes the root cause. Do not write
the patch — describe it in 2-4 sentences. Note any places the fix
could plausibly regress (REGRESSION-RISK candidates).

STEP 7 — Adversarial self-check.
- Is your worked example actually the bug, or a different bug that
  surfaces near the same code?
- Does the fix sketch work for ALL the call sites you found, or
  only some?
- Are there test fixtures that should now fail (and would expose
  this bug if run)?

OUTPUT: Write `docs/reviews/<DATE>-deep-review/forensic-<slug>.md`,
where `<slug>` is a short kebab-case derived from the claim title.

Format:
```
# Forensic: <claim title>

## Original claim
<one paragraph>

## Code-path walk
<step-by-step trace, file:line per step>

## Worked example
**Input:** ...
**Intermediate values:**
- step 1: ...
- step 2: ...
**Output:** ...
**Expected:** ...
**Delta:** ...

## Root cause
<one paragraph naming the specific line / default / design choice>

## Blast radius
<list of affected call sites; configurations affected>

## Smallest correct fix sketch
<2-4 sentences>

## Regression risk
<one line, or "none anticipated">
```

Length: 600-1500 words. Evidence-density > prose. The synthesis will
integrate this as the resolution for the original finding.
