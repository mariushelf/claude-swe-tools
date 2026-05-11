# Changelog

All notable changes to this project are documented in this file.

## [0.4.0] - 2026-05-11

### Added
- `swe-tools:deep-code-review` skill: multi-wave fan-out audit — a discovery agent surveys the codebase and emits themed review tasks; an orchestrator runs them in parallel (architecture, API ergonomics, dead-code, red-team, and optional conditional themes like numerics, event-flow, data-correctness, LLM-correctness); a synthesizer dedupes findings into a prioritised `SYNTHESIS.md`
- This CHANGELOG file

## [0.3.0] - 2026-05-07

### Added
- `swe-tools:go` skill: autonomous work mode that drives work to a PR without stopping
- `swe-tools:plan-and-go` skill: plan and implement a spec autonomously to PR using isolated subagents; spec must exist at `docs/specs/<slug>.md`
- Uncertainty log feature in `swe-tools:go`

### Changed
- design-advisor: renamed modes — `critique` → `review`, `review` → `check`
- design-advisor: synthesis output now opens with `# AI Team: <topic>` title and an AI attribution blockquote disclaimer
- design-advisor: updated synthesis language from "the team" to "the AI advisory team" throughout

### Removed
- Removed `claude-vault` plugin from the repository and marketplace

## [0.2.0] - 2026-05-06

### Added
- `swe-tools:go` and `swe-tools:plan-and-go` skills (pre-bump development, formally released in 0.3.0)

## [0.1.0] - 2026-03-16

### Added
- Initial release of the `swe-tools` plugin
- `swe-tools:design-advisor` skill: multi-perspective AI advisory board for architecture and design decisions
- `swe-tools:working-on-parallel-issues` skill: workflow for working on multiple GitHub issues in parallel using git worktrees
- Marketplace configuration (`marketplace.json`) for plugin discovery
