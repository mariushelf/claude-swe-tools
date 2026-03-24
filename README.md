# swe-tools

A curated collection of software engineering skills for Claude Code.

Beta: use at your own risk and provide feedback!

## Plugins

This marketplace package contains two installable plugins:

| Plugin | Description | Install command |
|--------|-------------|-----------------|
| **swe-tools** | Design advisor team and parallel issue workflows | `claude plugin install swe-tools@claude-swe-tools` |
| **claude-vault** | Persistent, git-versioned knowledge vault (Obsidian-browsable) | `claude plugin install claude-vault@claude-swe-tools` |

## Skills

### swe-tools

#### design-advisor

Spawn a 4-person agent team (architect, UX advocate, domain expert, devil's advocate) to advise on architecture, plan a solution, or review a proposed change — before any code is written.

**Modes:**
- `critique:` — open-ended architecture critique
- `plan:` — design a solution for a stated goal
- `review:` — evaluate a specific proposed change

**Usage:** `/design-advisor critique: the auth middleware's separation of concerns`

#### working-on-parallel-issues

Orchestrate multiple GitHub issues in parallel — one worktree-isolated agent per issue, each producing a PR with green CI.

The orchestrator avoids merge conflicts by serialising tasks that are likely to conflict
with each other.

Recommended to run in a dev container or other isolated environment with
`--dangerously-skip-permission` to allow for fully autonomous operation.

**Usage:** `/working-on-parallel-issues 128 129 130 131 134`

**Note:** Requires the [superpowers](https://github.com/obra/superpowers) plugin for the `dispatching-parallel-agents` orchestration pattern.

**Output**

![working-on-parallel-issues screenshot](swe-tools/docs/working-on-parallel-issues-screenshot.png)


### claude-vault

A persistent external brain for Claude — structured, git-versioned knowledge that survives across sessions and is browsable in [Obsidian](https://obsidian.md). Claude uses the vault proactively: checking for known gotchas before diving into a problem, suggesting captures when something worth remembering comes up, and offering a digest before you sign off.

**Entry types:** ADRs, gotchas, patterns, solutions, brainstorms, notes — each with YAML frontmatter and structured templates.

#### vault-status

Health check and first-run initialization. Shows projects, entry counts, and recent additions.

**Usage:** `/claude-vault:status`

#### vault-capture

Save a decision, gotcha, or pattern to the vault. Claude proposes the file and asks for approval before writing.

**Usage:** `/claude-vault:capture We decided to use event sourcing because CDC couldn't handle schema migrations`

#### vault-search

Find knowledge by keyword, tag, project, or type. Accepts natural language queries.

**Usage:** `/claude-vault:search --type gotcha sqlalchemy async`

#### vault-summary

End-of-session digest — scans the conversation for capturable knowledge and lets you pick what to save.

**Usage:** `/claude-vault:summary`

#### vault-analysis

Insights report across all projects — spots recurring gotchas, shipping streaks, stale projects, and tech debt signals. Delivered with personality.

**Usage:** `/claude-vault:analysis`

See the full [claude-vault README](claude-vault/README.md) for setup and vault structure details.

## Installation

First, add the marketplace:

```bash
claude plugin marketplace add mariushelf/claude-swe-tools
```

Then install whichever plugins you want:

```bash
claude plugin install swe-tools@claude-swe-tools
claude plugin install claude-vault@claude-swe-tools
```

Or interactively inside Claude Code:

```
/plugin marketplace add mariushelf/claude-swe-tools
/plugin install swe-tools@claude-swe-tools
/plugin install claude-vault@claude-swe-tools
```

## License

MIT
