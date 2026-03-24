---
name: vault-search
description: Search the knowledge vault by keyword, tag, project, or type. Returns structured results with file paths, titles, dates, and previews. PROACTIVE USE: When hitting a problem or debugging an issue, check the vault for existing gotchas and solutions before diving in. Mention any relevant findings to the user.
allowed-tools: Bash, Read, Grep, Glob
---

# Vault Search

Searches the vault using grep-based filtering with support for keywords, tags, projects, and types.

`VAULT_PATH` is `$HOME/claude-vault`. Check it exists; if not, tell user to run `/claude-vault:status` first.

## Usage

Parse `$ARGUMENTS` for search intent. Support natural language queries like:
- "gotchas about sqlalchemy" → `--type gotcha sqlalchemy`
- "all ADRs in project foo" → `--type adr --project foo`
- "tech/terraform" → `--tag tech/terraform`

Run the search script:

```bash
${CLAUDE_SKILL_DIR}/../../scripts/vault-search.sh "$HOME/claude-vault" [--type TYPE] [--tag TAG] [--project PROJECT] [KEYWORDS...]
```

## Presenting Results

- Format results in a readable markdown list
- For each result, show: type badge, file path, title, date, and preview
- If results are found, offer to read any specific file for full details
- If no results, say so and suggest broadening the search (fewer keywords, remove type filter, etc.)
