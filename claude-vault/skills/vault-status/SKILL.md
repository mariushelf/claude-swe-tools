---
name: vault-status
description: Show vault overview — projects, recent additions, counts by type. Also initializes the vault on first run and detects missing sandbox permissions. Use at the start of sessions to orient yourself, or when you need to check what's in the vault.
allowed-tools: Bash
---

# Vault Status

Shows the current state of the knowledge vault, handles first-run setup, and provides orientation.

## Single Command

```bash
${CLAUDE_SKILL_DIR}/../../bin/claude-vault status
```

## Interpreting Output

- If the output is `NO_VAULT`, ask the user: "No vault found at `~/claude-vault/`. Want me to initialize one?" If they agree, run:
  ```bash
  ${CLAUDE_SKILL_DIR}/../../bin/claude-vault init
  ```
- If `permissions: DENIED`, tell the user to add vault permissions. Provide the JSON from the README's First-Run Setup section.
- Otherwise, present the output in a clean, readable format with markdown formatting.
