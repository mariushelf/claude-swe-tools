---
name: working-on-parallel-issues
description: Use when asked to work on 2+ GitHub issues in parallel or in the background, each needing its own branch, worktree, and PR with CI verification
---

# Working on Parallel Issues

Orchestrate multiple GitHub issues in parallel — one worktree-isolated agent per issue, each producing a PR with green CI.

**Core principle:** You orchestrate only. Agents do all research, planning, and implementation autonomously. Do not try to understand the issues in depth — leave that to the agents.

**REQUIRED:** Use superpowers:dispatching-parallel-agents for the core orchestration pattern (overlap assessment, parallel vs sequential dispatch). This skill adds only the GitHub issue → PR pipeline rules.

## Pre-Dispatch (orchestrator only)

### 1. Overlap Assessment

Fetch all issues (`gh issue view <N>`). Scan titles and descriptions for obvious overlap.

- **Overlap obvious from titles** (e.g., two issues both mention "settings page"): skip scouts, sequence the overlapping issues directly.
- **Overlap unclear or 4+ issues**: dispatch one lightweight scout agent per issue. Each scout reads the issue/comments, explores the codebase, and returns a list of files expected to change plus a one-line summary.

### 2. Sequencing Decision

Compare file lists (from scouts or your own assessment). If two issues have significant file overlap, sequence them: dispatch the first, then dispatch the dependent agent with instructions to fetch and rebase on the first agent's branch before implementing. Otherwise, dispatch all in parallel.

## Agent Rules

Each agent runs with `isolation: "worktree"`. Every agent must:

1. Read the issue and all comments: `gh issue view <N>`
2. Create branch named `<N>-<short-title>` (e.g., `98-rename-use-case`)
3. Implement, run tests, commit (conventional commits), push
4. Create PR that closes the issue
5. **Verify CI is green:** poll `gh pr checks <PR-number>` until checks complete. If checks fail, read failure logs, fix, push, re-verify. **Job is not done until CI is green.**
6. If the issue is already implemented, report it and skip

### Underspecified Issues

If an issue is underspecified: implement your best interpretation, but add a `## Uncertain Spec` section to the PR description explaining what was ambiguous and what assumptions were made.

## Post-Dispatch

Report a status table as agents complete:

| Issue | Title | PR | CI |
|-------|-------|----|----|
| #45 | Dark mode toggle | #102 | green |
| #47 | Export button | #103 | green |

Close any duplicate PRs from interrupted runs.

## Common Mistakes

**Skipping CI verification** — agents naturally create the PR and stop. CI must be green before the job is done.

**Wrong worktree naming** — use `<N>-<short-title>`, not `feat/<N>-...` or verbose names.

**Over-conservative sequencing** — for overlapping issues, the dependent agent rebases on the first agent's *branch*, not waits for it to *merge*.
