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

**Always:** Do not stop until you have created a PR. Use `commit-commands:commit-push-pr` to commit, push, and open the PR.
