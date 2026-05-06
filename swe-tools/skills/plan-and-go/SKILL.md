---
description: Plan and implement an existing spec autonomously to PR, using subagents for cost and context isolation. Spec must exist at docs/specs/<slug>.md. Flags: "local"/"no-worktree" to skip worktree, "silent"/"no-questions" to skip questions.
---

Plan-and-implement an existing spec, autonomously, to PR. Arguments: $ARGUMENTS.

**Slug:** first non-flag arg, or the spec you just wrote in this session. If neither, ask or refuse. `docs/specs/<slug>.md` must exist.

**Precondition:** `gh` CLI authenticated.

**Worktree:**
- Default: use `superpowers:using-git-worktrees` to set up a new worktree on a new feature branch named after the slug.
- If arguments contain `local` or `no-worktree`: work in the current worktree.

**Questions:**
- Default: skim the spec; ask any clarifying questions the spec doesn't answer NOW, then proceed without stopping.
- If arguments contain `silent` or `no-questions`: skip questions, make your best judgment, start immediately.

## Phase 1 — Plan (subagent, opus)

Dispatch one general-purpose subagent:
- model: `opus`
- description: `"Write plan for <slug>"`
- prompt:
  ```
  Read docs/specs/<slug>.md.

  Use the superpowers:writing-plans skill to produce a plan at
  docs/plans/<slug>.md. Self-review the plan once before returning.

  Return only: the plan path and a one-paragraph summary of the
  approach. No play-by-play.
  ```

Show the user the plan path and summary, then immediately proceed to Phase 2. Do not stop for approval — autonomous mode.

## Phase 2 — Implement (subagent, sonnet)

Dispatch one general-purpose subagent:
- model: `sonnet`
- description: `"Implement plan for <slug>"`
- prompt:
  ```
  Read docs/specs/<slug>.md and docs/plans/<slug>.md.

  Use superpowers:executing-plans and superpowers:test-driven-development.
  For grep-heavy or read-only sub-tasks you may dispatch Haiku
  sub-subagents.

  Maintain an uncertainty log at `.uncertainty-<slug>.md` at the
  repo root (worktree root), where `<slug>` is the spec slug
  passed as the skill argument. The slug suffix keeps parallel
  runs from colliding on the same file. Append immediately —
  not retrospectively — whenever you:
  - Make a decision the spec/plan didn't clearly answer
    (record file:line and the alternative considered)
  - Stub, skip, weaken, or remove a test
  - Defer scope from the plan
  - Hit something that warrants close human review

  Use these sections, even if empty:
    ## Uncertain decisions
    ## Tests skipped/stubbed/weakened
    ## Scope deferred
    ## Review focus
  Write `<none>` under empty sections. Cap at ~50 entries total;
  consolidate if you would exceed. The file MUST NOT be committed.

  When facing a decision the spec/plan does not clearly answer,
  default to the SMALLER scope and log it as deferred, rather
  than guessing big.

  Run the full test suite, type checks, and lints. Fix failures
  or log them as uncertainties.

  Before opening the PR:
  1. Read `.uncertainty-<slug>.md` contents into memory.
  2. Delete `.uncertainty-<slug>.md`. Verify with `git status` it does
     not appear as added or modified.
  3. Use commit-commands:commit-push-pr to commit, push, and
     open the PR.
  4. The PR description must include the uncertainty log
     contents under a `## Review focus` section. If every
     section was `<none>`, the section content is
     `No uncertainties flagged.` If commit-commands:commit-push-pr
     does not accept a custom body, append the section
     afterwards using `gh pr edit <pr-number> --body-file -`.

  Return only: the PR URL and one sentence of overall confidence.
  No play-by-play.
  ```

When the implement subagent returns, show the user the PR URL and the confidence sentence. Done.

**Always:** Do not stop until the PR is created.
