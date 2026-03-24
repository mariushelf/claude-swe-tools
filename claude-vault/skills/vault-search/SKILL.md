---
name: vault-search
description: Search the knowledge vault by keyword, tag, project, or type. Returns structured results with file paths, titles, dates, and previews. PROACTIVE USE: When hitting a problem or debugging an issue, check the vault for existing gotchas and solutions before diving in. Mention any relevant findings to the user.
allowed-tools: Bash
---

# Vault Search

Searches the vault by keyword, tag, project, or type.

## Single Command

Parse `$ARGUMENTS` for search intent, then run one command:

```bash
${CLAUDE_SKILL_DIR}/../../bin/claude-vault search [--type TYPE] [--tag TAG] [--project PROJECT] [KEYWORD...]
```

Examples:
- `/vault-search sqlalchemy async` → `claude-vault search sqlalchemy async`
- `/vault-search --type gotcha terraform` → `claude-vault search --type gotcha terraform`
- `/vault-search --tag tech/postgres` → `claude-vault search --tag tech/postgres`

Present results in a readable format. If no results, say so.
