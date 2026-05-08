PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: Adversarial red-team. Hunt for **silent wrong-output**
scenarios — concrete inputs or sequences that produce a wrong result
without raising, logging, or otherwise alerting the user. Read-only.

The bar for a finding: "given this realistic input, the system
silently produces an incorrect answer that the user trusts."

STEP 1 — Build the failure surface.
For each public function or entry point, list:
- What the user expects it to compute / produce.
- What input space the user might pass.
- What configuration / state the user might pre-load.
- What edge cases (empty / single / NaN / huge / negative / duplicate
  / out-of-order / locale-dependent) are possible.

STEP 2 — Generate adversarial scenarios.
For each function, enumerate **at least three** scenarios where the
output could be silently wrong. Use these classes of attack:

A) **Boundary inputs**
- Empty input, single-element input, all-identical input.
- Very large / very small magnitudes (1e9, 1e-9).
- Negative values where the function assumed positive.
- NaN / inf / null.
- Off-by-one boundaries (window sizes, ranges, slices).

B) **Out-of-order / duplicate / time-skipped data**
- Time-series with duplicate timestamps.
- Time-series with gaps.
- Time-series with retrograde timestamps.
- Time-series with timezone-naive vs aware mixing.

C) **Configuration drift**
- Two near-identical configs that produce silently different results
  because of a default that doesn't propagate correctly.
- Default arguments that compose into a wrong overall state.
- A documented option that has no effect (silent no-op).

D) **Composability traps**
- Calling A then B vs B then A produces different output.
- Calling A twice produces double the effect (not idempotent).
- Calling A on the output of A produces nonsense.

E) **Future-data leak / hidden coupling**
- A function that "looks at the current row" but actually peeks at
  the next row via shift / rolling / fill-forward (any time-ordered
  data: logs, events, metrics, sensor readings, financial bars).
- A function that depends on global state set elsewhere.
- A function whose output at time T depends on data from time T+1
  in any indirect way (cache populated by a future call, shared
  buffer pre-filled by a sibling task, etc.).

F) **Silent type coercion**
- An int passed where a float was expected, producing integer
  division on Python 2-style code (or wrong rounding on Python 3).
- A pandas/polars Series passed where a scalar was expected,
  triggering broadcasting.
- A list passed where a single element was expected, producing N
  copies.

G) **Failure-as-success**
- Network/IO call fails, exception is caught and a default value
  silently returned.
- A required dependency is missing, a fallback is used, no warning.
- Schema validation fails, the row is dropped without logging.

H) **Determinism breaks**
- A reduction over an unordered set that returns a different value
  per run.
- A `uuid` or random ID baked into output that breaks reproducibility.

**Coverage requirement.** For each of categories A through H above, generate
**at least 2 scenarios** applicable to this codebase — even if those scenarios
aren't on the `$SUSPECT_INVENTORY`. Generic adversarial inputs (duplicate
timestamps, reversed-order data, NaN passthrough, off-by-one boundaries)
must be enumerated for every codebase, regardless of what discovery surfaced.
A theme review with 0 scenarios in any category is incomplete.

STEP 3 — Verify reachability.
For each scenario, walk the code path: can a realistic caller actually
hit it? If only an internal author with admin access could trigger
it, downgrade to P2.

STEP 4 — Adversarial self-check.
For each scenario, ask: "is this a real silent-wrong, or would a
reasonable user notice the problem (an exception, a clearly nonsense
output, a log warning)?" Keep only the silent ones.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/red-team.md`.

For each scenario:
- ID (`RT-NN`).
- Title.
- Setup / preconditions.
- Concrete adversarial input (1-3 lines of pseudocode).
- Expected (correct) output.
- Actual (silently-wrong) output, with file:line of the path that
  produces it.
- Severity (P0 silent wrong-output, P1 degraded, P2 stylistic).
- Detection: how a user would *eventually* notice (or never).

Aim 20-40 concrete scenarios. 1500-2000 words. End with a top-10
silently-wrong list, prioritised by realistic-frequency × magnitude.
