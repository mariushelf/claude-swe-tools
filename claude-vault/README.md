# claude-vault

claude-vault is a Claude Code plugin that gives Claude a persistent external brain — a structured, git-versioned knowledge vault that survives across sessions. Decisions, gotchas, patterns, and solutions are captured as Markdown files with YAML frontmatter, organized by project and type, and fully browsable in Obsidian. Claude uses the vault proactively: checking for known gotchas before diving into a problem, suggesting captures when something worth remembering comes up, and offering an end-of-session digest before you sign off.

## Installation

From the command line:

```bash
claude plugin marketplace add mariushelf/claude-swe-tools
claude plugin install claude-vault@claude-swe-tools
```

Or interactively inside Claude Code:

```
/plugin marketplace add mariushelf/claude-swe-tools
/plugin install claude-vault@claude-swe-tools
```

## First-Run Setup

### 1. Sandbox Write Permissions

Claude Code runs in a filesystem sandbox. Add `~/claude-vault` to the write allowlist in `~/.claude/settings.json`:

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": ["~/claude-vault"]
    }
  }
}
```

### 2. Vault Initialization

Run `/claude-vault:status` in any Claude Code session. If no vault is found, Claude will offer to initialize one automatically by running `vault-init.sh`.

### 3. Obsidian Setup (Optional)

Open `~/claude-vault` as a vault in [Obsidian](https://obsidian.md). Install the **Dataview** community plugin for live dashboards and queries over the vault contents.

## Skills

### `/claude-vault:status` — Vault health and first-run init

Shows an overview of the vault: projects, entry counts by type, and the 5 most recent additions. Handles first-run initialization and detects missing sandbox permissions.

**Example:**
```
/claude-vault:status
```
> Use at the start of a session to orient yourself, or any time you want a quick pulse-check on what's in the vault.

---

### `/claude-vault:capture` — Save knowledge to the vault

Captures a decision (ADR), gotcha, pattern, solution, brainstorm, or note with structured frontmatter. Claude proposes the full file content and asks for approval before writing. ADRs are numbered sequentially per project; knowledge items (gotchas, patterns, solutions) live under `knowledge/` and are searchable across all projects.

**Examples:**
```
/claude-vault:capture We decided to use event sourcing for the audit trail because CDC couldn't handle schema migrations
```
```
/claude-vault:capture SQLAlchemy async sessions don't auto-close — need explicit session.close() after create_async_engine
```
```
/claude-vault:capture --type pattern Retry with exponential backoff for flaky external API calls
```

---

### `/claude-vault:search` — Find knowledge by keyword, tag, or type

Searches the vault using grep-based filtering. Accepts natural language or structured arguments. Returns results with type, title, date, and a content preview.

**Examples:**
```
/claude-vault:search sqlalchemy async
```
```
/claude-vault:search --type gotcha terraform
```
```
/claude-vault:search --type adr --project my-project
```
```
/claude-vault:search --tag tech/postgres
```

---

### `/claude-vault:summary` — End-of-session knowledge capture

Reviews the current conversation for decisions, gotchas, patterns, and solutions worth keeping. Proposes a numbered list and asks which items to capture before writing anything.

**Example:**
```
/claude-vault:summary
```
> Claude will respond with something like:
> ```
> 1. [gotcha] "SQLAlchemy async sessions don't auto-close"
> 2. [adr] "Use event sourcing for audit trail"
> 3. [pattern] "Retry with exponential backoff"
>
> Which items should I capture? (e.g., "1, 3", "all", or "none")
> ```

---

### `/claude-vault:analysis` — Work insights report

Scans titles, tags, type counts, and git history (not full file contents) to produce an insights report across all projects. Identifies shipping streaks, debugging spirals, recurring gotchas, stale projects, and tech debt signals. Delivered with personality.

**Example:**
```
/claude-vault:analysis
```
> Sample output excerpt:
> ```
> You've been wrestling with SQLAlchemy sessions for TWO WEEKS across 3 projects. Dude. Write a wrapper and be done with it.
> project-x: 11 notes in the last 5 days?! You absolute machine. Ship it!
> project-y hasn't seen action since February. RIP or just resting?
> ```

---

## Vault Structure

```
~/claude-vault/
├── _index.md              # Vault-level index (projects + recent entries)
├── projects/
│   └── <project-name>/
│       ├── _index.md      # Project index
│       ├── adrs/          # Architecture decision records (numbered)
│       ├── brainstorms/
│       └── notes/
├── knowledge/
│   ├── gotchas/           # Cross-cutting gotchas (searchable across projects)
│   ├── patterns/          # Reusable patterns
│   └── solutions/         # Solutions to tricky problems
└── templates/             # Vault-level Obsidian templates
```

Each entry is a Markdown file with YAML frontmatter (`title`, `date`, `type`, `project`, `tags`) and a structured body. All files are git-committed on write, giving you a full history of captured knowledge.

## Roadmap

### Phase 2 — Semantic Search

- **memsearch integration**: Augment full-text search with vector-based semantic search, enabling queries like "find notes similar to this idea" or "what have I captured about eventual consistency?" rather than exact keyword matching. The `.memsearch/` index directory is generated locally and excluded from the git repository.
