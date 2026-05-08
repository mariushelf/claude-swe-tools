PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
FINDINGS_TO_VERIFY: $FINDINGS_TO_VERIFY  (list of finding IDs + claims, OR path to a prior review document such as a previously-produced SYNTHESIS.md)

YOUR ROLE: Verifier (wave 3). Re-walk each claim in `$FINDINGS_TO_VERIFY`
against the actual code and decide: is it CONFIRMED, REFUTED, or
INCONCLUSIVE. Read-only.

This wave runs after themed deep-dives produce findings, OR when the
user provides a prior review doc and asks "are these claims still
true?" The job is to be the skeptic — themed agents over-anchor on
their narrative; you do not.

STEP 1 — Parse the input.
For each entry in `$FINDINGS_TO_VERIFY`, extract:
- Finding ID.
- Claim (one-sentence summary of what's wrong).
- Cited evidence (file:line, code snippet).
- Severity tier the original review assigned.

STEP 2 — Re-walk each claim.
For each finding, **without trusting the original wording**:
- Open the cited file and lines. Does the code at those lines match
  the snippet quoted in the finding?
- Trace the call graph: who calls this code path, with what inputs?
- Is there a guard, validation, or upstream invariant that prevents
  the failure mode?
- Is there a test that would catch the failure mode? Does it pass?
- Does the failure mode actually fire in a realistic configuration,
  or only in a contrived one?

STEP 3 — Classify.
- **CONFIRMED** — the claim matches the code; the failure mode is
  reachable; severity is at least what the original review assigned.
- **CONFIRMED, RE-TIERED** — the claim matches but severity should
  be different (give your tier and a one-line reason).
- **REFUTED** — the code doesn't actually do what the finding said,
  OR there's an upstream guard that prevents the failure mode, OR the
  code path is unreachable in practice. State the reason in one line.
- **INCONCLUSIVE** — the claim involves runtime behaviour you can't
  determine from reading code alone (e.g., "this is slow under load",
  "this leaks memory after 1000 calls"). Note what would resolve it
  (a test, a forensic trace, a benchmark).

STEP 4 — Look for missed findings.
While walking the cited code paths, you will sometimes notice
adjacent issues the original reviewer didn't flag. Note these
under "ADJACENT FINDINGS" with the same status as a regular finding.
Do not exhaustively re-review — only flag things you trip over while
verifying.

STEP 5 — Adversarial self-check.
For each REFUTED finding: is your refutation actually correct, or
did you miss a code path? Re-grep for the symbol / pattern across
the whole codebase before finalising a refutation.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/verifier.md`.

Format:
```
## CONFIRMED (N findings)
| ID | Original severity | Confirmed severity | Notes |

## REFUTED (N findings)
| ID | Original claim | Why refuted |

## INCONCLUSIVE (N findings)
| ID | Claim | What would resolve it |

## ADJACENT FINDINGS (N findings)
| ID (V-NN) | Title | Evidence | Severity |
```

Length: scales with input. 600-1500 words typical. Be terse — the
synthesizer will integrate this into SYNTHESIS.md.
