PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: Dead-code / aspirational-code hunter. Find code that exists
in the tree but does nothing useful, code that's in the way of
understanding, and code that promises features it doesn't deliver.
Read-only.

STEP 1 — Find unwired classes / modules.
- For each public class / function in the scope, grep for callers.
- A "caller" is a non-test file that imports it AND uses it (`Foo()`
  or `foo()`, not just `import foo`).
- Note: tests-only callers count as "test-only", not "live". If a
  class is only exercised by its own unit test and never used by the
  application, it's dead.

STEP 2 — Find aspirational stubs.
- Functions whose body is `pass`, `...`, `raise NotImplementedError`,
  or `return None  # TODO`.
- Classes with no methods that take a "subclass me" docstring.
- Files that open with `# TODO remove this file` or `# WIP`.
- Files that haven't been touched in months but contain `# placeholder`.

STEP 3 — Find duplicate concepts.
- Two classes with similar names + similar fields (e.g., `User` and
  `UserModel`, `Order` and `OrderRequest`, two `Settings`).
- A type alias that's never used (e.g.,
  `StepSize: TypeAlias = LotSize`).
- A second implementation of a concept that's already done well
  elsewhere (e.g., a hand-rolled "rolling window" alongside
  `pandas.rolling`).

STEP 4 — Find unreachable / no-op code.
- `if record.size * 0.0 < 0:` → mathematically unreachable.
- Conditions that depend on a hardcoded constant comparison
  (`if False:`, `if True:`).
- Branches gated by a flag that's never set to anything but its
  default.
- `try` blocks whose `except` body silently passes and whose code
  cannot raise the listed exception.

STEP 5 — Find leftover scaffolding.
- Commented-out code blocks of more than 3 lines.
- `print(...)` / `console.log(...)` left in production paths.
- `import pdb; pdb.set_trace()` or equivalents.
- Test-only hooks that bypass invariants (e.g., `_force_state`).

STEP 6 — Find empty `__all__` / unbalanced exports.
- Modules that export nothing.
- `composition/__init__.py` (or equivalent re-export module) that
  exports half of what it should.
- `__init__.py` files whose only role is hiding internal structure
  but which leak it via `from .foo import *`.

STEP 7 — Find untouched-since-X code.
- For each suspicious file, run `git log --oneline -- <file>` (last
  10 commits). If the file hasn't been touched in 6+ months and
  contains `TODO` / `XXX` / `FIXME`, it's likely abandoned.
- Note: use `git log --oneline | head -10` to gauge total project
  activity first; "6 months untouched" is relative to project age.

STEP 8 — Adversarial self-check.
For each finding: is the code actually dead, or is it called via a
mechanism your search missed (reflection, dynamic import, plugin
registration, decorator side-effect, dependency-injection container)?
Run a final, broader grep: `grep -r '<symbol>' --include='*.<ext>'`.
If you can't find any non-test caller, classify confidently.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/dead-code.md`.

Each finding has: ID (`DC-NN`), what it is (file:line), evidence of
deadness (no callers / unreachable branch / empty body), suggested
action (delete / wire / mark with TODO + ticket), severity
(P1 confusing / P2 cosmetic / P3 truly harmless).

Length: 600-1200 words. Group by sub-theme (unwired / aspirational /
duplicate / unreachable / scaffolding / empty-exports).

End with a "delete-list": files / symbols safe to delete in one
mechanical PR, and a "wire-or-delete" list for things that are
ambiguous.
