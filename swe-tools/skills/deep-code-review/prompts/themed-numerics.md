PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: Numerics reviewer. Find places where floating-point,
determinism, epsilons, NaN/inf, integer overflow, or rounding will
silently produce wrong output. Read-only.

STEP 1 — Numeric type inventory.
Grep for the project's numeric quantities. For each meaningful one
(money, quantity, probability, score, weight, count, time, …):
- What type is it stored as: `float`, `int`, `Decimal`, `Fraction`,
  numpy/polars/pandas dtype, custom type?
- How is arithmetic done? Any rounding policy declared?
- Is the choice consistent across modules, or does the same quantity
  switch type at a boundary?

STEP 2 — Comparison and epsilon audit.
Grep for:
- `math.isclose`, `math.isnan`, `math.isinf`, `numpy.isclose`
- `abs(a - b) < ` patterns
- `== 0.0`, `!= 0.0`, `<= 0`, `< 0` on float-typed values
- Magic constants `1e-9`, `1e-12`, etc.

For each: is the epsilon calibrated to the quantity's scale (units,
order of magnitude)? Is the same epsilon used consistently, or do
nearby comparisons use different ones?

STEP 3 — NaN / inf / null propagation.
For each numerical input boundary (file/network/user input, computed
divisions, log/sqrt of unchecked values):
- Is NaN / inf possible? Validated at the boundary?
- What happens if NaN enters: does it short-circuit or silently spread?
- Is there a `fill_null(strategy="forward")` or similar that hides
  real gaps?
- Any comparison of NaN that returns False and silently skips a branch?

Common silent-NaN traps:
- `x / y` where `y` may be 0
- `log(x)` where `x ≤ 0`
- `sqrt(x)` where `x < 0`
- `x ** 0.5` (silently coerces neg to NaN in numpy/polars)
- `cumsum` over a column with one NaN row
- Mean/std of an all-NaN window

STEP 4 — Accumulation and order-dependence.
- Running sums over many values: how does float drift accumulate?
- Streaming weighted-average / running mean / online-variance: does
  it commute? Does the result depend on the order of incremental
  updates, or only on the final set?
- Any reduction whose result depends on the input order
  (`sum([huge, -huge, small])` ≠ `sum([small, huge, -huge])`)?
- Polars/pandas group-by aggregations on float columns: stable across
  reorderings?

STEP 5 — Determinism.
Grep for non-deterministic sources and check if they affect output:
- `uuid.uuid4`, `uuid.uuid1`, `secrets.`
- `random.`, `numpy.random.` (with vs without seed)
- `hash(`, `set(`, `frozenset(`, `dict.popitem`
- Iteration over an unordered set, frozenset, or pre-3.7 dict
- `os.urandom`, `time.time` injected into output
- Float ops where compiler reordering matters (`-ffast-math` flags,
  fused multiply-add, etc., for languages where applicable)

For each: does it affect the project's externally-visible output? Is
there a seed or stable ordering? If not, can repeated runs produce
byte-different artefacts?

STEP 6 — Quantisation and rounding.
- Step-size / grid-snap enforcement using `%` on float (unreliable):
  e.g., `0.3 % 0.1 ≠ 0.0` in IEEE 754.
- "Round to N decimal places" via `round(x, n)` (banker's rounding,
  not half-up).
- Truncation / int-cast that silently loses precision.
- Conversion between `float` and `Decimal` mid-pipeline.

STEP 7 — Library-specific traps (skip sections that don't apply).

Polars / pandas:
- `fill_null(strategy="forward")` masking real gaps.
- `shift(-1)` future-data leak (using row T+1 to compute row T).
- `group_by_dynamic` or `rolling` aggregations on columns that
  shouldn't be `.last()`-aggregated.
- Schema-implicit dtype coercion that silently casts int → float.

Numpy:
- Accidental broadcast that produces a 2D result from 1D inputs.
- `np.float32` vs `np.float64` mixing in a single expression.

JavaScript / TypeScript:
- `Number` coverage for large integers (>2⁵³).
- `Date` arithmetic on timezone-naive Unix timestamps.

STEP 8 — Adversarial self-check.
For each finding: produce a concrete adversarial input that triggers
the wrong output. If you can't, downgrade the severity.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/numerics.md`.

Each finding has: ID (`N-NN`), title, evidence (file:line + snippet),
what's wrong, adversarial input that triggers it, severity (P0 silent
wrong number / P1 degraded / P2 stylistic).

Length: 900-1500 words. Evidence-heavy. Group findings by sub-theme
(types / comparisons / NaN / accumulation / determinism / quantisation
/ library-specific).
