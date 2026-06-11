# Changelog

All notable changes to this project are documented in this file.

## [0.7.0] - 2026-06-12

### Added
- `swe-tools:check-docs` gains `since:` / `range:` arguments: a recency window (default anchor: the commit that produced the last `DOC_AUDIT.md`) that *prioritises* findings on recently-changed code rather than restricting the audit. In-window findings are tagged `recent`, boosted a severity step, and sorted to the top under a "Recent changes" section; code that churned while its covering page did not is surfaced as a likely-stale signal. Dates resolve to a boundary commit (`git rev-list -1 --before=…`), not `git log --since`. All four lenses still run against current source, and a windowed report is explicitly never a clean bill of health for the whole site

## [0.6.0] - 2026-06-11

### Added
- `swe-tools:document-pr` skill: PR-scoped documentation gate that leans on `check-docs` and `update-docs`. Resolves a pull request's diff and either validates the doc edits the PR already ships (against the code it changes, without failing the PR on pre-existing drift or rewriting the author's prose) or writes the docs a change with no doc edits needs — always scoped to the diff, never the whole repository

## [0.5.0] - 2026-06-11

### Added
- `swe-tools:check-docs` skill: read-only documentation audit for Python repositories — fans out parallel agents across four lenses (coverage, drift, structure, voice) and synthesises a single prioritised `DOC_AUDIT.md`; never writes to the docs tree
- `swe-tools:update-docs` skill: writer counterpart to `check-docs` — creates, repairs, and restructures docs against source code into a Sphinx/Diátaxis layout, then wires and build-verifies them; handles greenfield and legacy repos and can consume a curated `DOC_AUDIT.md`

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
