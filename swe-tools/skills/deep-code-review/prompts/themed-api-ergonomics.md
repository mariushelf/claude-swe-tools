PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: API ergonomics reviewer. Treat the public surface as a
library someone else has to use. Find friction points: bad defaults,
implicit invariants, surprises, missing extension hooks, naming traps.
Read-only.

STEP 1 — Identify the public surface.
- What does `__init__.py` export at the top level?
- What does the project's manifest declare as entry points?
- For each consumer-facing class / function: what does its signature
  promise? What do its docstring + type hints say?
- Are there example scripts / quickstart docs / notebooks? Read them
  and note where they reach into "private" namespaces (a sign the
  public API is missing something).

STEP 2 — Default-value audit.
For each public function with default arguments:
- Is the default the value most users would want, or does it silently
  create incorrect behaviour for the most common case?
- Is the default safe (no surprises) or unsafe (silent network
  fallback, default-tenant scoping, default RNG seed of 0, default
  file-write to cwd, default unlimited retries, …)?
- Does the default differ from the documented "recommended" value?
- Is `None` used as a default that secretly means "use the global
  config", "use a magic constant", or "skip this step entirely"?

STEP 3 — Implicit invariants.
- What must the caller pre-validate that the function doesn't
  validate itself?
- What ordering is required across multiple function calls (e.g.,
  `attach()` before `run()`) without a runtime guard?
- What types are accepted that look generic but secretly need extra
  attributes (duck-typing without protocols)?
- What invariants are documented but unenforced, vs enforced but
  undocumented?

STEP 4 — Naming traps.
- Two functions / classes whose names suggest they do the same thing
  but behave differently.
- A name from one domain reused in another with different semantics.
- A misspelling or typo in a public name that future renames will
  break.
- Plural vs singular inconsistencies in collection accessors.
- Verb-vs-noun inconsistencies on similar methods (`get_X` vs
  `fetch_X` vs `read_X`).

STEP 5 — Extension hooks.
- For each "this should be customisable" surface, is there a Protocol,
  ABC, or callback parameter? Or do users have to monkey-patch / fork?
- Are extension hooks declared with concrete types (`callable`,
  function references) or with rich Protocols?
- Are infrastructure types accidentally part of the public API
  because the constructor accepts them?

STEP 6 — Errors and observability.
- When the user does something wrong, what error do they see? Is it
  actionable, or does it surface deep in the stack with no context?
- Is there a "config validation" step at startup, or do problems only
  surface mid-run?
- Are warnings used for things that should be errors? Errors for
  things that should be warnings?

STEP 7 — Documentation vs reality.
- Pick 5 concrete claims from `README` / docstrings / quickstart and
  verify against the code. Note any drift.
- Find any class / function that has a beautiful docstring but is
  unused or unwired. ("aspirational doc, real-only API surface")
- Find any class / function that's heavily used but has no docstring
  beyond its name.

STEP 8 — Adversarial self-check.
For each finding: imagine a new user opens the project today. Would
they hit this? If only an internal author would, downgrade to P2.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/api-ergonomics.md`.

Each finding has: ID (`API-NN`), title, evidence (file:line + snippet),
what's wrong, what a new user would expect, severity (P0 silent
wrong-output via bad default / P1 user-visible friction / P2 cosmetic).

Length: 900-1500 words. Group by sub-theme (defaults / invariants /
naming / extension / errors / docs).
