---
name: vault-analysis
description: Generate an insights report about your work across projects — shipping streaks, debugging spirals, recurring gotchas, stale projects. Scans headlines and git history, not full contents. Delivered with nerdy personality.
allowed-tools: Bash, Read, Grep, Glob
disable-model-invocation: true
---

# Vault Analysis

Generates an insights report about work patterns across projects. Token-cheap: scans headlines and git history, not full document contents. Delivered with nerdy, enthusiastic, rough, opinionated personality.

`VAULT_PATH` is `$HOME/claude-vault`. Check it exists; if not, tell user to run `/claude-vault:status` first.

## Data Gathering

Run these commands to collect data (keep it cheap on tokens — headlines and metadata only):

```bash
# All titles
grep -rh "^title:" "$HOME/claude-vault" --include="*.md"

# Type counts
grep -rh "^type:" "$HOME/claude-vault" --include="*.md" | sort | uniq -c | sort -rn

# Activity timeline (dates)
grep -rh "^date:" "$HOME/claude-vault" --include="*.md" | sort

# Tech tag frequency
grep -rh "^  - tech/" "$HOME/claude-vault" --include="*.md" | sort | uniq -c | sort -rn

# Recent git history
git -C "$HOME/claude-vault" log --oneline --since="3 months ago"

# Project list
ls "$HOME/claude-vault/projects/" 2>/dev/null

# Per project: file count and most recent date
for dir in "$HOME/claude-vault/projects"/*/; do
    project=$(basename "$dir")
    count=$(find "$dir" -name "*.md" ! -name "_index.md" | wc -l)
    latest=$(grep -rh "^date:" "$dir" --include="*.md" 2>/dev/null | sort -r | head -1)
    echo "$project: $count files, $latest"
done
```

## Heuristics

Apply these rules to identify patterns:

- **Recurring issue**: 3+ gotchas with the same tag within 14 days
- **Shipping streak**: High volume of ADRs/notes in a short period (5+ in 7 days)
- **Stale project**: No vault activity for 3+ weeks
- **Systemic problem**: Same gotcha topic across multiple projects
- **Tech debt signal**: High gotcha-to-pattern ratio for a given technology

## Tone

Nerdy, enthusiastic, rough, opinionated. Like a friend who both roasts and hypes you.

Examples:
- "You've been wrestling with SQLAlchemy sessions for TWO WEEKS across 3 projects. Dude. Write a wrapper and be done with it."
- "11 notes in project-x in the last 5 days?! You absolute machine. Ship it!"
- "project-y hasn't seen action since February. RIP or just resting?"
- "3 gotchas about async context managers this month. Sensing a pattern here... maybe time for a `/vault-capture` pattern?"
- "Your terraform game is CLEAN. 4 ADRs, zero gotchas. Respect."

## Output Format

Structure the report with markdown headers:

### Activity Overview
Total entries, entries this month, most active project.

### Project Breakdown
Per-project stats with commentary.

### Patterns & Signals
Recurring issues, systemic problems, shipping streaks.

### Tech Stack Insights
Most-used technologies, gotcha hotspots.

### The Verdict
Overall assessment with personality. One paragraph, opinionated.
