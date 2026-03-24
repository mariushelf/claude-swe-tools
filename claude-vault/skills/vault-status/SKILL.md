---
name: vault-status
description: Show vault overview — projects, recent additions, counts by type. Also initializes the vault on first run and detects missing sandbox permissions. Use at the start of sessions to orient yourself, or when you need to check what's in the vault.
allowed-tools: Read, Glob, Grep, Bash
---

# Vault Status

Shows the current state of the knowledge vault, handles first-run setup, and provides orientation.

`VAULT_PATH` is `$HOME/claude-vault`.

## Permission Check

Test if the vault path is writable by attempting a small write:

```bash
touch "$HOME/claude-vault/.vault-lock" 2>/dev/null && rm -f "$HOME/claude-vault/.vault-lock"
```

If this fails, tell the user they need to add the vault to their sandbox allowlist. Provide the exact JSON to add to `~/.claude/settings.json`:

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": ["~/claude-vault"]
    }
  }
}
```

## Vault Initialization

If `$HOME/claude-vault` does not exist, ask the user: "No vault found at `~/claude-vault/`. Want me to initialize one?"

If they agree, run:

```bash
${CLAUDE_SKILL_DIR}/../../scripts/vault-init.sh "$HOME/claude-vault"
```

Then confirm initialization succeeded by checking the directory exists.

## Status Display

If the vault exists, gather and display:

### Projects

```bash
ls -d "$HOME/claude-vault/projects"/*/ 2>/dev/null | xargs -I{} basename {} | sort
```

### Counts by Type

```bash
grep -rl "^type: adr" "$HOME/claude-vault" --include="*.md" 2>/dev/null | wc -l
grep -rl "^type: brainstorm" "$HOME/claude-vault" --include="*.md" 2>/dev/null | wc -l
grep -rl "^type: pattern" "$HOME/claude-vault" --include="*.md" 2>/dev/null | wc -l
grep -rl "^type: gotcha" "$HOME/claude-vault" --include="*.md" 2>/dev/null | wc -l
grep -rl "^type: solution" "$HOME/claude-vault" --include="*.md" 2>/dev/null | wc -l
grep -rl "^type: note" "$HOME/claude-vault" --include="*.md" 2>/dev/null | wc -l
```

### Recent Entries

```bash
grep -rn "^date:" "$HOME/claude-vault" --include="*.md" | sort -t: -k3 -r | head -5
```

For each result, also extract the title from the same file's frontmatter.

### Git Status

```bash
git -C "$HOME/claude-vault" status --short
```

Present the output in a clean, readable format with markdown headers.
