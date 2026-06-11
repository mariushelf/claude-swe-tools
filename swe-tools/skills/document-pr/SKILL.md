---
name: document-pr
description: >
  Use when a pull request touches a Python repository's documented surface
  and its documentation must be kept in sync with the change — whether the
  PR already ships doc edits or none at all. Use as a pre-merge or pre-push
  documentation gate scoped to a single PR or branch, not a whole-repo pass.
argument-hint: "[pr: <number>] [base: <ref>] [scope: <path>] [mode: auto|validate|update]"
disable-model-invocation: false
---

# Document PR

Keeps a pull request's documentation in step with its code. A PR is a *diff*, so
this skill scopes all documentation work to exactly what the PR changed and
delegates the heavy lifting to its two siblings: it **validates** existing doc
edits with the read-only `check-docs`, and **writes** missing docs with
`update-docs`. It is the PR-scoped front door to that pair — not a new audit or
writer of its own.

The governing decision is simple: **if the PR already edits documentation,
validate those edits against the code change; if it does not, write the docs the
change needs.** Either way the unit of work is the diff, never the whole site.

**REQUIRED SUB-SKILL:** Use swe-tools:check-docs for the read-only audit.
**REQUIRED SUB-SKILL:** Use swe-tools:update-docs to write or repair pages.

## When to use

- A PR changes public API, endpoints, settings, or architecture and its docs
  must be created or updated before merge.
- A PR already edits docs and you want to confirm those edits match the code it
  changes — and that nothing the code changed was left undocumented.
- As a pre-merge / pre-push gate that flags doc drift introduced *by this PR*
  without auditing the whole repository.

**Don't use** for: a whole-repo audit (use `check-docs`), a whole-repo
create/restructure (use `update-docs`), or reviewing code correctness (use
`deep-code-review`).

## Arguments

`$ARGUMENTS` — optional. The keys are a vocabulary, not a grammar; plain prose
works too (`validate the docs on PR 142`) and maps to the same effect.

- **`pr:`** the PR to document, by number. Default: the current branch's PR if
  one exists, otherwise the current branch diffed against its base.
- **`base:`** the ref the PR merges into, for computing the diff. Default: the
  PR's base branch (from `gh`), or the repo's default branch for a bare branch.
- **`scope:`** narrow the work to a path *within* the PR's changes — the diff is
  still the outer bound. Default: everything the PR touches.
- **`mode:`** document-pr's own routing knob — **never forwarded** to
  `update-docs` (whose unrelated `mode:` cap, `touch-up`/`overhaul`, stays at its
  default). `auto` (default) decides the path from the diff and is **report-only
  on the validate path**; `validate` never writes under any path (a pure gate);
  `update` also fills the coverage the PR is missing. Gap-filling therefore
  requires `mode: update`.

## Decision: validate or update

The diff drives one of three paths:

- **The diff edits doc pages → validate.** Audit those edits against the code
  change; report gaps and contradictions. Fill only *missing* coverage, and only
  under `mode: update` — never silently rewrite the author's prose.
- **The diff edits no docs but touches documented surface → update.** Write the
  docs the change needs.
- **The diff touches no documented surface → no-op.** Report that no
  documentation is required.

"Doc pages" here means whatever `check-docs` classifies as documentation — the
published `docs/source/` tree, or a legacy docs layout — **not** `docs/reviews/`
audit reports or a top-level `README`. (`update-docs` reserves the word
"rendered" for `docs/source/` only; this skill's routing intentionally covers
legacy docs too.)

## Workflow

### 1. Scope the PR

Resolve the diff once, deterministically — no subagent:

- With `pr:`, read `gh pr view <n> --json baseRefName,headRefName,files` and
  `gh pr diff <n>`. Without it, diff the current branch against its base with
  `git diff <base>...HEAD` (three-dot already diffs against the merge-base). If
  local `HEAD` is ahead of the PR's remote head ref, prefer the local diff and
  say so in the report — `gh pr diff` reflects only what has been pushed.
- Split the changed paths into **code paths** (the documented surface that may
  have moved) and **doc paths** (changes under the published docs tree).
- Keep the hunks, not just the file list: validation compares the *doc delta*
  against the *code delta*, so the changed lines are what matter.

### 2a. Validate — the PR already edits docs

The author's doc edits are the thing under test. Invoke `check-docs` (via the
Skill tool) **once**, with `scope:` given as prose that enumerates the changed
code files and changed doc pages (its scope is "a vocabulary, not a grammar," so
a scattered file list is legal), and an explicit `out:` pointing **outside the
PR's committed tree** — a scratch path, or a `docs/reviews/<date>-pr<N>-doc-audit/`
directory you do not stage. A gate must not dirty or commit into the branch it is
judging. Then read the resulting `DOC_AUDIT.md` **through the PR diff**:

| Finding | Bears on the PR? | Verdict |
|---------|------------------|---------|
| A symbol the PR changed is undocumented or contradicted | yes | PR doc gap/error — fails the gate |
| A doc page the PR added/edited is off-voice or mis-placed | yes | PR issue |
| Drift unrelated to the diff (pre-existing) | no | out of PR scope — list for follow-up, do not fail the PR |

`check-docs` runs its voice lens only conditionally (legacy repos without their
own voice rules skip it), so an empty voice result is not by itself a PASS on
voice — say which lenses ran.

Report the verdict — **PASS**, or **ISSUES** with the list. Validation **never
rewrites the author's prose.**

Gap-filling (only under `mode: update`; `auto` and `validate` are report-only
here) reuses the audit you already have instead of triggering a second one:
**curate that `DOC_AUDIT.md`** — set every out-of-PR finding and every
human-prose contradiction to `skip`/`leave`, leaving only the PR's *missing*
coverage actionable — then invoke `update-docs report:<that path>`. In report
mode `update-docs` trusts the curated file and does not re-audit, so coverage is
filled additively and the author's prose is never auto-edited.

### 2b. Update — the PR ships no docs

Under `mode: validate` (a pure gate), do **not** write: run `check-docs` as in 2a
over the changed code paths and report the absent pages as **ISSUES**. The
read-only promise holds under every path.

Otherwise delegate to `update-docs scope: <changed code paths>`. Its own `mode:`
cap is left at its default — this skill's `mode:` is never forwarded. It runs its
own scoped `check-docs`, writes the pages, wires them into the `toctree`, and
build-verifies. This skill only sets the scope from the diff and summarises the
result for the PR. Composition is by skill invocation, so the audit and writing
logic stay single-source in the siblings.

### 2c. No-op

The diff touches only undocumented surface (tests, CI, an internal refactor with
no API change). This branch is decided *without* `check-docs`, so guard it:
before declaring a no-op, confirm (a) no changed file adds or alters public
surface — API routes, settings, public functions/classes, CLI — and (b) a search
of the changed symbol names under the docs tree finds no page that documents
them. If either check fires, fall through to 2a/2b. Otherwise say so and write
nothing.

### 3. Report

Emit a concise, PR-scoped summary fit for a PR comment or the description: what
was validated or written, and what still needs a human. Posting it to the PR
(`gh pr comment`) is **opt-in** — do it only when asked, never by default.

## Common mistakes

- **Auditing the whole subtree and failing the PR on pre-existing drift.** Read
  `check-docs` findings through the diff; only what the PR changed is the gate.
- **Rewriting the contributor's prose.** Validation reports; it does not edit
  human-authored pages. Gap-filling is additive only.
- **Treating `docs/reviews/` or `README` edits as "the PR ships docs."** Those
  are not doc pages; they do not flip the path to validate.
- **Re-implementing the audit.** Always invoke `check-docs`/`update-docs`; never
  copy their prompts or logic here.

## Non-goals

- Not a whole-repo audit or rewrite — the diff is the hard boundary.
- Never fails a PR on pre-existing drift unrelated to its changes.
- Never silently rewrites human-authored doc prose in the PR; it reports.
- Never merges, approves, or comments on the PR unless explicitly asked.

See `README.md` for the human workflow and how the validate/update split mirrors
`check-docs` / `update-docs`.
