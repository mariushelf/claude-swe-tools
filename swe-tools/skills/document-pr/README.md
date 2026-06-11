# document-pr

Keeps a pull request's documentation in step with its diff. It is the PR-scoped
front door to the [`check-docs`](../check-docs/README.md) /
[`update-docs`](../update-docs/README.md) pair: it derives the changed surface
from the PR, then either **validates** the doc edits the PR already carries or
**writes** the docs the change needs — always scoped to the diff, never the
whole site.

## The core idea: a PR is a diff

`check-docs` and `update-docs` operate on a *scoped subtree* and measure it
against current source. That is the right tool for "is this module documented?"
but the wrong unit for a pull request. A PR is a **change**, and the only
documentation question a merge gate should answer is: *does this change leave the
docs consistent?*

So `document-pr` resolves the PR's diff first and makes it the hard boundary.
Pre-existing drift in a file the PR happens to touch is not this PR's
responsibility — it is noted for follow-up, never a reason to block the merge.
This keeps the gate honest: it reacts to what the author did, not to the
accumulated debt of the whole repository.

## Validate vs update

The diff itself decides the path:

- **The PR already edits doc pages → validate.** The author's edits are the
  thing under test. The skill audits them against the code the PR changes and
  reports a verdict, but it **does not rewrite human-authored prose** — a
  contributor who wrote the wrong thing gets a finding to act on, not a silent
  overwrite. Where the PR simply *missed* a surface (changed code, no
  corresponding page), the skill can fill that gap additively when asked.
- **The PR ships no docs → update.** The skill writes the pages the change needs
  by handing the diff's code paths to `update-docs`.
- **The PR touches no documented surface → no-op.** Tests, CI, and internal
  refactors with no API change need nothing.

"Doc pages" deliberately excludes `docs/reviews/` audit reports and a top-level
`README` — editing those does not flip the path to *validate*. (`update-docs`
reserves the word "rendered" for `docs/source/` only; this skill also routes
legacy docs.)

## How it leans on the pair

`document-pr` adds no audit or writer of its own. It composes the siblings **by
skill invocation** — the same discipline `update-docs` uses when it calls
`check-docs` — so the audit and authoring logic stay single-source. The skill's
only original work is deterministic and small: resolve the diff, split it into
code and doc paths, choose the path, and — on the validate path — read the
resulting `DOC_AUDIT.md` *through* the diff so the verdict is about the PR and
nothing else.

## Human workflow

1. On a feature branch (or against an open PR with `pr: <n>`), run the skill.
2. Read the verdict:
   - **validate** → PASS, or a list of PR-scoped gaps/contradictions plus any
     pre-existing drift flagged separately for follow-up.
   - **update** → the pages written and wired by `update-docs`, build-verified.
     Run with `mode: validate` to turn even this branch into a pure report-only
     gate (missing pages become ISSUES rather than being written) — useful in CI.
3. Act on what is reported — fix prose the skill flagged, or let it fill missing
   coverage (`mode: update`). Posting the summary as a PR comment is opt-in.

## What it does not do

- No whole-repo audit or rewrite — use `check-docs` / `update-docs` for that.
- Never blocks a PR on drift it did not introduce.
- Never overwrites a contributor's documentation prose.
- Never merges, approves, or comments on a PR unless explicitly asked.
