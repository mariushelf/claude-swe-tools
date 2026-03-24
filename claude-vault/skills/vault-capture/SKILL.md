---
name: vault-capture
description: Save knowledge to the vault — decisions (ADRs), gotchas, patterns, solutions, brainstorms, or notes. Proposes a structured file with frontmatter and asks for approval before writing. PROACTIVE USE: When you spot a decision, gotcha, reusable pattern, or tricky solution during work, suggest this skill to the user. Only suggest for knowledge that would save future sessions real time — don't interrupt flow for trivial things.
allowed-tools: Bash, Read
---

# Vault Capture

Captures knowledge to the vault with structured frontmatter and Obsidian-compatible formatting.

## Step 1: Gather Metadata

1. Parse `$ARGUMENTS` for what to capture. If empty, ask the user.
2. Determine **type** from context or ask: adr, brainstorm, pattern, gotcha, solution, note
3. Determine **project** from context or ask. If cross-cutting knowledge, leave project empty.
4. Suggest **tags** reusing existing ones:
   ```bash
   ${CLAUDE_SKILL_DIR}/../../bin/claude-vault tags
   ```
5. Check for **supersession**: does this replace an existing note? If so, identify the old file.

## Step 2: Generate Content

Read the template from `${CLAUDE_SKILL_DIR}/templates/<type>.md`. Fill in:
- All frontmatter fields (title, date, type, project, tags, supersedes, related)
- All body sections with content from the conversation context
- Remove optional frontmatter fields that are empty

## Step 3: Preview and Approve

Show the complete file content to the user. Ask: "Capture this?"

## Step 4: Write and Commit (on approval)

Write the content to a temp file, then run a single command:

```bash
${CLAUDE_SKILL_DIR}/../../bin/claude-vault capture \
  --type TYPE \
  --project PROJECT \
  --title "TITLE" \
  --file /tmp/claude-vault-entry.md \
  [--supersedes "old/relative/path.md"]
```

This single command handles: writing to the correct path, updating project and vault indices, and git committing.

Report the output to the user (captured path and commit message).
