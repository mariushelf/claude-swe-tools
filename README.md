# swe-tools

A curated collection of software engineering skills for Claude Code.

Beta: use at your own risk and provide feedback!

## Plugins

This marketplace package contains one installable plugin:

| Plugin | Description | Install command |
|--------|-------------|-----------------|
| **swe-tools** | Design advisor team and parallel issue workflows | `claude plugin install swe-tools@claude-swe-tools` |

## Skills

### swe-tools

#### design-advisor

Spawn a 4-person agent team (architect, UX advocate, domain expert, devil's advocate) to advise on architecture, plan a solution, or review a proposed change — before any code is written.

**Modes:**
- `critique:` — open-ended architecture critique
- `plan:` — design a solution for a stated goal
- `review:` — evaluate a specific proposed change

**Usage:** `/design-advisor critique: the auth middleware's separation of concerns`

#### deep-code-review

Multi-wave fan-out of read-only specialist agents that audit a codebase for silent-wrong-output bugs, architectural drift, and aspirational dead code. Self-configures: a discovery agent reads the codebase and recommends themes; the orchestrator dispatches them in parallel against an always-on quality floor; a synthesizer dedupes and prioritises everything into a single findings document.

**Always-on themes:** `architecture`, `api-ergonomics`, `dead-code`, `red-team`.
**Conditional themes:** `numerics`, `event-flow`, `data-correctness`, `llm-correctness` — dispatched only when discovery sees the relevant surface.
**Custom themes:** discovery invents domain-specific themes (e.g., frontend state management, IaC correctness) via a meta-template when no pre-tuned theme covers the surface.

**Usage:**
```
/deep-code-review
/deep-code-review scope: src/auth
/deep-code-review verifier: docs/reviews/2025-12-01-deep-review/SYNTHESIS.md
```

Output: `docs/reviews/<YYYY-MM-DD>-deep-review/SYNTHESIS.md` plus per-theme appendix files. See the [deep-code-review README](swe-tools/skills/deep-code-review/README.md) for the design philosophy and theme catalogue.

#### check-docs

A read-only audit of a Python repository's documentation against its source code. It surveys the repo, fans out cheap parallel agents across four lenses — coverage, drift, structure, voice — and synthesises a single prioritised `DOC_AUDIT.md`. **It never touches the rendered docs tree or any existing file** — the report is the only thing it writes.

The report is the contract with the writer skill, `update-docs`: every finding carries a per-page `action` a human can edit, and `update-docs` consumes the curated report. Mirrors `deep-code-review` (read-only, emits a findings doc) — safe to run anywhere, including CI or a repo nobody owns.

`since:`/`range:` anchor a **recency window** (default anchor: the last `DOC_AUDIT.md`) and **narrow the audit to the docs that window touched** — the pages changed in it plus the pages covering code changed in it. It is the cheap, focused path: each in-scope page is still audited in full against current source, pages whose code churned but whose docs did not are flagged `stale-risk` and sorted first, and the report opens with a disclaimer that a windowed run is a partial audit, never a clean bill of health for the whole site.

**Usage:**
```
/check-docs
/check-docs scope: src/clustering
/check-docs since: v1.4.0
/check-docs since: 2026-01-01
/check-docs out: docs/reviews/doc-audit.md
```

Output: `docs/reviews/DOC_AUDIT.md` (unrendered). See the [check-docs README](swe-tools/skills/check-docs/README.md).

#### update-docs

The writer counterpart to `check-docs`. Creates, repairs, and restructures a Python repository's documentation against its source code, then wires and build-verifies it. Handles both greenfield repos (derive docs from code) and legacy repos (re-verify facts, restructure into a Sphinx/Diátaxis layout, rewrite to voice). It can consume a curated `DOC_AUDIT.md` from `check-docs`, or run standalone.

A global `mode` flag (`auto`/`touch-up`/`overhaul`) sets the default invasiveness; per-finding `action`s from the audit refine it page by page.

**Usage:**
```
/update-docs
/update-docs report: docs/reviews/DOC_AUDIT.md
/update-docs mode: touch-up scope: src/clustering
```

Output: written and build-verified pages under `docs/`. See the [update-docs README](swe-tools/skills/update-docs/README.md).

#### document-pr

Keeps a single pull request's documentation in step with its diff. It is the PR-scoped front door to `check-docs` / `update-docs`: it resolves the PR's changed surface, then **validates** the doc edits the PR already carries (against the code it changes, never failing the PR on pre-existing drift) or **writes** the docs the change needs — always scoped to the diff, never the whole site. The decision is driven by the diff: if the PR already edits rendered docs it validates them (and never rewrites the author's prose); if it ships no docs it writes them; if it touches no documented surface it does nothing.

**Usage:**
```
/document-pr
/document-pr pr: 142
/document-pr mode: validate scope: src/clustering
```

Output: a PR-scoped verdict (validate) or pages written and build-verified by `update-docs` (update). See the [document-pr README](swe-tools/skills/document-pr/README.md).

#### working-on-parallel-issues

Orchestrate multiple GitHub issues in parallel — one worktree-isolated agent per issue, each producing a PR with green CI.

The orchestrator avoids merge conflicts by serialising tasks that are likely to conflict
with each other.

Recommended to run in a dev container or other isolated environment with
`--dangerously-skip-permission` to allow for fully autonomous operation.

**Usage:** `/working-on-parallel-issues 128 129 130 131 134`

**Note:** Requires the [superpowers](https://github.com/obra/superpowers) plugin for the `dispatching-parallel-agents` orchestration pattern.

**Output**

![working-on-parallel-issues screenshot](swe-tools/docs/working-on-parallel-issues-screenshot.png)

## Installation

First, add the marketplace:

```bash
claude plugin marketplace add mariushelf/claude-swe-tools
```

Then install the plugin:

```bash
claude plugin install swe-tools@claude-swe-tools
```

Or interactively inside Claude Code:

```
/plugin marketplace add mariushelf/claude-swe-tools
/plugin install swe-tools@claude-swe-tools
```

## License

MIT
