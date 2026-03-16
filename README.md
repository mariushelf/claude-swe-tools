# swe-tools

A curated collection of software engineering skills for Claude Code.

## Skills

### design-advisor

Spawn a 4-person agent team (architect, UX advocate, domain expert, devil's advocate) to advise on architecture, plan a solution, or review a proposed change — before any code is written.

**Modes:**
- `critique:` — open-ended architecture critique
- `plan:` — design a solution for a stated goal
- `review:` — evaluate a specific proposed change

**Usage:** `/design-advisor critique: the auth middleware's separation of concerns`

### working-on-parallel-issues

Orchestrate multiple GitHub issues in parallel — one worktree-isolated agent per issue, each producing a PR with green CI.

**Usage:** `/working-on-parallel-issues 45 47 52`

**Note:** Requires the [superpowers](https://github.com/obra/superpowers) plugin for the `dispatching-parallel-agents` orchestration pattern.

## Installation

```bash
claude plugin add --from github:mariushelf/swe-tools
```

## License

MIT
