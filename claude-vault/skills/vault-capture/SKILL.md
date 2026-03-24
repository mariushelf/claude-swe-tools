---
name: vault-capture
description: Save knowledge to the vault — decisions (ADRs), gotchas, patterns, solutions, brainstorms, or notes. Proposes a structured file with frontmatter and asks for approval before writing. PROACTIVE USE: When you spot a decision, gotcha, reusable pattern, or tricky solution during work, suggest this skill to the user. Only suggest for knowledge that would save future sessions real time — don't interrupt flow for trivial things.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Vault Capture

Captures knowledge to the vault with structured frontmatter and Obsidian-compatible formatting.

`VAULT_PATH` is `$HOME/claude-vault`. Check it exists; if not, tell user to run `/claude-vault:status` first.

## Step 1: Gather Metadata

1. Parse `$ARGUMENTS` for what to capture. If empty, ask the user.
2. Determine **type** from context or ask: adr, brainstorm, pattern, gotcha, solution, note
3. Determine **project** from context or ask. If cross-cutting knowledge, leave project empty.
4. Suggest **tags** reusing existing ones from the vault:
   ```bash
   grep -rh "^  - " "$HOME/claude-vault" --include="*.md" | sort -u | head -30
   ```
5. Check for **supersession**: does this replace an existing note? If so, identify the old file.

## Step 2: Generate Filename and Path

- **ADRs**: scan the project's `adrs/` dir for the highest number, increment:
  ```bash
  ls "$HOME/claude-vault/projects/$PROJECT/adrs/" 2>/dev/null | grep -oP '^\d+' | sort -n | tail -1
  ```
  Format: `NNNN-YYYY-MM-DD-kebab-title.md` (zero-padded to 4 digits)
- **All other types**: `YYYY-MM-DD-kebab-title.md`

Path routing:
- **ADRs, brainstorms, notes** → always under project: `$VAULT_PATH/projects/$PROJECT/{type}s/$FILENAME`
- **Patterns, gotchas, solutions** → always under knowledge: `$VAULT_PATH/knowledge/{type}s/$FILENAME` (use the `project` frontmatter field to associate with a project, but the file lives in `knowledge/`)
- Create subdirectories with `mkdir -p` if they don't exist.

## Step 3: Generate Content

Read the template from `${CLAUDE_SKILL_DIR}/templates/<type>.md`. Fill in:
- All frontmatter fields (title, date, type, project, tags, supersedes, related)
- All body sections with content from the conversation context
- Remove optional frontmatter fields that are empty (don't include `project:` if cross-cutting, don't include `supersedes:` if not superseding)

## Step 4: Preview and Approve

Show the complete file content to the user. Ask: "Write this to `<path>`?"

## Step 5: Write and Commit (on approval)

Execute in order:

1. Write the file to the determined path
2. If superseding: read the old file, add `superseded_by: "[[new-file]]"` to its frontmatter, write it back
3. Update the **project or knowledge `_index.md`**:
   ```bash
   ${CLAUDE_SKILL_DIR}/../../scripts/index-update.sh "$HOME/claude-vault" "<index-file>" "<section>" "<entry>"
   ```
   - For project ADRs/brainstorms/notes: update `projects/$PROJECT/_index.md` in the matching section
   - For knowledge items: there is no per-folder index; only update the vault-level index
4. Update the **vault-level `_index.md`** directly using Read + Edit:
   - If this is a new project, add it to the Projects section
   - Update Knowledge counts by grepping:
     ```bash
     grep -rl "^type: pattern" "$HOME/claude-vault/knowledge/" --include="*.md" | wc -l
     grep -rl "^type: gotcha" "$HOME/claude-vault/knowledge/" --include="*.md" | wc -l
     grep -rl "^type: solution" "$HOME/claude-vault/knowledge/" --include="*.md" | wc -l
     ```
   - Prepend to Recent section (keep last 10 entries, remove oldest if > 10)
   - If superseding: strikethrough the old entry in any index where it appears
5. Git add only the specific files touched and commit:
   ```bash
   git -C "$HOME/claude-vault" add <new-file> <index-files-touched> [<old-superseded-file>]
   git -C "$HOME/claude-vault" commit -m "<type>(<project>): <title>"
   ```
   For cross-cutting: `git -C "$HOME/claude-vault" commit -m "<type>: <title>"`
