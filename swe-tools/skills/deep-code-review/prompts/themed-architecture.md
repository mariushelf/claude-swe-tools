PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: Architecture reviewer. Find layering violations, unsound
abstractions, coupling problems, and patterns that will silently slow
down evolution. **Trust code, not docs**. Read-only.

STEP 1 — Map the actual structure.
Walk the directory tree under $SCOPE. For each top-level grouping:
- What does it claim to be (by name or docstring)?
- What does the code actually do?
- What does it import? What imports it?

STEP 2 — Identify the architectural pattern.
Is this hexagonal, layered, monolith, plugin, pipeline, MVC, ad-hoc? Is
the chosen pattern actually enforced, or is it aspirational?

STEP 3 — Check for layering violations.
- Does anything in a "domain" / "core" layer import from infrastructure
  or framework code?
- Does anything in a "model" or "entity" layer reach into application
  services?
- Are dependency injection / port-adapter boundaries respected, or are
  there hidden imports?
- Are there `if TYPE_CHECKING:` or `import-linter exclude` patterns
  hiding a real dependency?
- Run any import-linter / dependency-cruiser config that exists; if
  results disagree with the source's organisation, flag it.

STEP 4 — Find leaky abstractions.
- Adapter exposing concrete details its port doesn't promise.
- Aggregate roots reaching into stores or repositories directly.
- Public functions that take "private" types from another layer.
- Re-exports that turn one layer's concept into another's.

STEP 5 — Find coupling problems.
- Circular imports (actual or near-misses requiring late-binding).
- Modules that import everything from a "kitchen sink" file.
- A type whose value flows through ten files without ever being
  transformed.
- Two modules that constantly change together (`git log --name-only`
  for the last 30 commits — touching both).

STEP 6 — Find duplicated abstractions.
- Two implementations of the same concept (e.g., two `Settings` classes,
  two `Result` types, two `User` records).
- Aliases that diverged silently.
- "Wrapper of a wrapper" with no value-add.

STEP 7 — Adversarial self-check.
For each finding: "is this real coupling or just file proximity?" Drop
the borderline ones; keep the load-bearing ones.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/architecture.md`.

Each finding has: ID (`AR-NN`), title, evidence (file:line + snippet),
what's wrong, why it matters, severity (P0 wrong-output / P1 degraded /
P2 maintainability), suggested direction (one sentence).

Length: 1200-2000 words. Evidence-density > prose. Group findings by
sub-theme (layering / leaky abstraction / coupling / duplication).
