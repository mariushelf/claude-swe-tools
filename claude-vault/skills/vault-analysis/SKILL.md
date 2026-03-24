---
name: vault-analysis
description: Generate an insights report about your work across projects — shipping streaks, debugging spirals, recurring gotchas, stale projects. Scans headlines and git history, not full contents. Delivered with nerdy personality.
allowed-tools: Bash
disable-model-invocation: true
---

# Vault Analysis

Generates an insights report about work patterns across projects.

## Single Command

```bash
${CLAUDE_SKILL_DIR}/../../bin/claude-vault analysis
```

This gathers all metadata (titles, type counts, dates, tags, git history, project breakdown) in one call.

## Heuristics

Apply these rules to the gathered data:

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

## Output Format

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
