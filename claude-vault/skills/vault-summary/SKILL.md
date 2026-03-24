---
name: vault-summary
description: End-of-session digest — reviews the conversation for decisions, gotchas, patterns, and solutions worth capturing, then proposes them as a numbered list for approval. PROACTIVE USE: Before a session ends or when the user says goodbye, offer to run this skill to capture notable knowledge from the conversation.
allowed-tools: Bash, Read
---

# Vault Summary

End-of-session digest that reviews the conversation for capturable knowledge.

## Step 1: Scan Conversation

Review the conversation for:
- **Decisions** made (ADRs)
- **Gotchas** discovered
- **Patterns** identified
- **Solutions** to tricky problems
- **Brainstorms** explored
- **Notes** worth keeping

Only propose items that would save future-you real time. Skip trivial or obvious things.

## Step 2: Propose Items

Present a numbered list:
```
1. [gotcha] "SQLAlchemy async sessions don't auto-close"
2. [adr] "Use event sourcing for audit trail"
3. [pattern] "Retry with exponential backoff"

Which items should I capture? (e.g., "1, 3", "all", or "none")
```

## Step 3: Capture Approved Items

For each approved item, generate the content, write it to a temp file, and run:

```bash
${CLAUDE_SKILL_DIR}/../../bin/claude-vault capture \
  --type TYPE \
  --project PROJECT \
  --title "TITLE" \
  --file /tmp/claude-vault-entry.md
```

For batch captures, no individual preview is needed — the user already approved the list. Write each entry's content to the temp file and run the capture command. One capture call per item.

## Tag Conventions

Check existing tags first:
```bash
${CLAUDE_SKILL_DIR}/../../bin/claude-vault tags
```

Standard namespaces: `tech/`, `domain/`, `practice/`
