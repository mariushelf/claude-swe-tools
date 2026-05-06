---
description: Start autonomous work mode — work without stopping until a PR is created. Flags: "local" or "no-worktree" to skip worktree, "silent" or "no-questions" to skip questions.
---

Switch to autonomous mode. Arguments: $ARGUMENTS

**Worktree:**
- Default: use `superpowers:using-git-worktrees` to set up a new worktree on a new feature branch
- If arguments contain `local` or `no-worktree`: work in the current worktree

**Questions:**
- Default: ask all clarifying questions now, then proceed without stopping
- If arguments contain `silent` or `no-questions`: skip questions, make your best judgment, start immediately

**Uncertainty log (always):**

At the very start of the run, capture a unique run id (e.g. `date +%Y%m%d-%H%M%S` or `date +%s`) and use it for the rest of the run. Maintain `.uncertainty-<run-id>.md` at the repo root (worktree root, or current working directory in `local` mode). The run-id suffix lets parallel `go` runs in the same checkout coexist without collision.

Append immediately — not retrospectively at the end — whenever you:
- Make a decision the conversation didn't clearly answer (record file:line and the alternative considered)
- Stub, skip, weaken, or remove a test
- Defer scope from the original ask
- Hit something that warrants close human review

Use these sections, even if empty:
```
## Uncertain decisions
## Tests skipped/stubbed/weakened
## Scope deferred
## Review focus
```
Write `<none>` under empty sections. Cap at ~50 entries total; consolidate if you would exceed.

The file MUST NOT be committed. It is your scratch log only.

**Finishing:**

1. Read `.uncertainty-<run-id>.md` contents into memory.
2. Delete `.uncertainty-<run-id>.md`. Verify with `git status` that it does not appear as added or modified.
3. Use `commit-commands:commit-push-pr` to commit, push, and open the PR.
4. The PR description must include the uncertainty log contents under a `## Review focus` section. If every section was `<none>`, the section content is `No uncertainties flagged.` If `commit-commands:commit-push-pr` does not accept a custom body, append the section to the PR description afterwards using `gh pr edit <pr-number> --body-file -`.

**Always:** Do not stop until you have created a PR.
