---
name: vault-summary
description: End-of-session digest — reviews the conversation for decisions, gotchas, patterns, and solutions worth capturing, then proposes them as a numbered list for approval. PROACTIVE USE: Before a session ends or when the user says goodbye, offer to run this skill to capture notable knowledge from the conversation.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Vault Summary

End-of-session digest that reviews the conversation and captures notable knowledge to the vault.

`VAULT_PATH` is `$HOME/claude-vault`. Check it exists; if not, tell user to run `/claude-vault:status` first.

## Step 1: Review Conversation

Scan the current conversation for capturable knowledge:
- **Decisions made** → ADR candidates
- **Gotchas encountered** → gotcha entries
- **Patterns discovered or applied** → pattern entries
- **Solutions to tricky problems** → solution entries
- **Brainstorm outcomes** → brainstorm entries
- **Noteworthy context** → note entries

Only propose items that would save future-you real time. Skip trivial or obvious things.

## Step 2: Propose Items

Present a numbered list with proposed type, title, and 1-sentence summary:

```
1. [gotcha] "SQLAlchemy async sessions don't auto-close" — Sessions created with create_async_engine need explicit close()
2. [adr] "Use event sourcing for audit trail" — Chose event sourcing over CDC for compliance requirements
3. [pattern] "Retry with exponential backoff" — Standard approach for flaky external API calls
```

Ask: "Which items should I capture? (e.g., '1, 3', 'all', or 'none')"

## Step 3: Capture Approved Items

For each approved item, execute the capture workflow directly (do NOT invoke the vault-capture skill — reimplement inline):

1. Determine type, project, tags, filename, and path using the same rules as vault-capture:
   - **ADRs, brainstorms, notes** → `$VAULT_PATH/projects/$PROJECT/{type}s/`
   - **Patterns, gotchas, solutions** → `$VAULT_PATH/knowledge/{type}s/`
   - ADR filenames: `NNNN-YYYY-MM-DD-kebab-title.md`
   - Others: `YYYY-MM-DD-kebab-title.md`
2. Read the template from `skills/vault-capture/templates/<type>.md` (path: `${CLAUDE_SKILL_DIR}/../vault-capture/templates/<type>.md`)
3. Generate the full file with frontmatter and content filled in from conversation context
4. Write the file, create directories with `mkdir -p` if needed
5. Update the relevant `_index.md`:
   ```bash
   ${CLAUDE_SKILL_DIR}/../../scripts/index-update.sh "$HOME/claude-vault" "<index-file>" "<section>" "<entry>"
   ```
6. Update vault-level `_index.md` Knowledge counts and Recent section via Read + Edit
7. Git add specific files and commit with conventional prefix:
   ```bash
   git -C "$HOME/claude-vault" add <files...>
   git -C "$HOME/claude-vault" commit -m "<type>(<project>): <title>"
   ```
   One commit per item.

Skip the individual preview step — the user already approved the batch. Only show previews if the user specifically asks.

## Tag Conventions

Reuse existing tags from the vault when possible:
```bash
grep -rh "^  - " "$HOME/claude-vault" --include="*.md" | sort -u | head -30
```

Standard namespaces: `tech/`, `domain/`, `practice/`
