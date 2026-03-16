---
name: design-advisor
description: >
  Use when needing architecture advice, design critique, or proposal
  review before writing code — especially for cross-cutting changes,
  new features, or refactoring decisions that affect multiple layers.
argument-hint: "critique|plan|review: [area, goal, or proposal to evaluate]"
disable-model-invocation: false
---

# Design Advisor Team

Spawn an agent team to advise on architecture, plan a solution, or evaluate
a proposed change **before any code is written**. The team debates from four
competing perspectives and produces a consensus recommendation.

## Arguments

$ARGUMENTS — prefixed with a mode keyword:

- **`critique:`** open-ended architecture critique. The team identifies
  problems and prioritises them. No refactoring is proposed.
- **`plan:`** design a solution to achieve a stated goal. The architect
  leads, others react.
- **`review:`** evaluate a specific proposed change.

If no prefix is given, infer the mode from context. Default to `critique`.

Example: `/design-advisor critique: the recording screen's state management`

## Lead Workflow

1. **Discover project context:**
   - Read CLAUDE.md (root and component-level), README.md, and any docs/
     directory to learn: architecture pattern, tech stack, domain, core UX
     promise, key directories, conventions, and current project maturity.
   - Compose a $PROJECT_CONTEXT summary (5-10 bullet points).
2. **Parse arguments:** determine $MODE (critique/plan/review) from the
   prefix. Strip the prefix to get $ARGUMENTS.
3. **Prepare prompts:** for each teammate, read their prompt file from
   `prompts/` and substitute `$MODE`, `$ARGUMENTS`, and `$PROJECT_CONTEXT`.
4. **Create team and tasks** per the Task Structure below.
5. **Synthesize** after all teammates report, per the Lead Synthesis template.

## Team Setup

Create an agent team called `design-advisor`. Spawn **four teammates** plus
yourself as the coordinating lead. Use delegate mode (do not implement anything
yourself).

**Model selection**: Use `sonnet` for all teammates by default. Only use `opus`
if the user explicitly requests it (e.g., `/design-advisor opus: critique ...`).

### Teammates

| # | Name | Concern | Prompt |
|---|------|---------|--------|
| 1 | `architect` | Clean internal architecture | `prompts/architect.md` |
| 2 | `ux-advocate` | End-user experience and workflow simplicity | `prompts/ux-advocate.md` |
| 3 | `domain-expert` | Domain correctness, API constraints, best practices | `prompts/domain-expert.md` |
| 4 | `devils-advocate` | Prevent overengineering and unnecessary complexity | `prompts/devils-advocate.md` |

All teammates are read-only. They explore code but do NOT edit or write files.

## Task Structure

The task flow depends on the mode. Within each step, teammates NOT listed
as blocked run independently of each other.

| Step | Critique | Plan | Review |
|------|----------|------|--------|
| 1 | architect, ux, domain explore code (parallel) | domain: define requirements + ux: assess surface (parallel) | architect, ux, domain explore code (parallel) |
| 2 | architect reports | architect proposes design (blocked: 1) | architect evaluates |
| 3 | ux reports | domain validates design (blocked: 2) | ux reviews |
| 4 | domain reports | ux reviews UX impact (blocked: 2) | domain reviews |
| 5 | devil's advocate challenges (blocked: 2,3,4) | devil's advocate challenges (blocked: 2) | devil's advocate challenges (blocked: 2,3,4) |
| 6 | lead synthesizes (blocked: 2-5) | lead synthesizes (blocked: 3,4,5) | lead synthesizes (blocked: 2-5) |

## Lead Synthesis

After all four perspectives are in, write a summary tailored to the mode.

### For critique mode

1. **Problem inventory**: ranked list of issues, with agreement/disagreement
   across the four perspectives.
2. **Domain correctness assessment**: are domain concepts modeled correctly?
   Flag anything the domain expert identified as incorrect or misleading.
3. **Recommended actions**: which issues to address, in what order, with the
   agreed approach for each.
4. **Dissent log**: unresolved disagreements.
5. **Current UX assessment**: is the user-facing flow good, or does it need work?
6. **Files involved**: list of files relevant to each identified issue.

### For plan / review mode

1. **Recommendation**: proceed / modify / abandon.
2. **Agreed design** (if proceeding): the concrete proposal, incorporating
   domain corrections, UX mitigations, and complexity reductions.
3. **Domain correctness verdict**: does the design correctly model the
   relevant domain concepts? Any remaining concerns?
4. **Dissent log**: unresolved disagreements.
5. **User-facing UX diff**: describe the user flow before and after. If
   unchanged, state that explicitly.
6. **Files affected**: list of files the implementation would touch.

Present this to the user for approval before any implementation begins.

## Important

- This skill is for **planning and review only**. No code is written.
- All teammates are read-only explorers. The lead coordinates and synthesizes.
- If the team unanimously agrees a change is unnecessary, say so clearly
  and recommend not doing it.
