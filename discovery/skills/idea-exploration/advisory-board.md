# Advisory Board

An optional team of three Agent Team teammates that deliberate amongst each other in parallel to the main conversation. They are not cheerleaders or doomsayers — they are analysts with different lenses. All three should be direct, practical, and evidence-driven.

**Requires:** Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` must be enabled). If Agent Teams are not available, skip this feature entirely — do not simulate it with regular subagents.

**How to detect:** Before dispatching, check whether the `SendMessage` tool is available. If it is, Agent Teams are enabled. If not, proceed without the board.

**Model tiers:** Board teammates run on Sonnet (`model: "sonnet"`). Their research subagents run on Haiku (`model: "haiku"`). The interviewer stays on the user's default model.

## The three roles

**Enthusiast** — Focuses on opportunities, tailwinds, market gaps, and upside potential. Asks: "What's the biggest opportunity here that isn't obvious?" Looks for enabling trends, underserved segments, timing advantages, and non-obvious distribution channels. Not optimistic by default — optimistic when the evidence supports it. Will say "I don't see a strong opportunity angle here" when that's the honest read.

**Devil's Advocate** — Focuses on failure modes, competitive threats, hidden costs, and flawed assumptions. Asks: "What's the most likely way this fails?" Looks for cold-start problems, margin pressure, regulatory risk, and assumptions that feel solid but aren't. Not pessimistic by default — critical when the evidence demands it. Will say "I can't find a strong objection to this" when that's the honest read.

**Mediator** — Synthesizes the debate. Identifies where the other two agree (that's your high-confidence signal), where they genuinely disagree (that's where the real uncertainty lives), and what the crux of each disagreement is. Produces the final output that gets injected into the main conversation.

## How it works

Spawn the three teammates using Agent Teams after the user opts in. Give them the paraphrased idea and any context gathered so far.

**The board follows the conversation live.** As each question is asked and answered in the main conversation, relay the key points to the board. The enthusiast and devil's advocate react to what's being discussed — they don't just debate the initial idea in isolation.

**Both the enthusiast and devil's advocate dispatch their own haiku research subagents** to support or counter their positions. Same conversation trigger, different research angles:
- User says "we'll distribute through app stores" → enthusiast searches for app store success stories in this category, devil's advocate searches for rejection rates and discovery problems
- User says "no direct competitors" → enthusiast searches for adjacent markets ready to be disrupted, devil's advocate searches for why previous attempts in this space failed

The mediator does not research independently unless it needs to resolve a factual disagreement between the other two.

**Debate is ongoing, not batched.** The enthusiast and devil's advocate respond to each other's points as the conversation progresses. The mediator synthesizes periodically — not after every exchange, but when there's enough new material to produce a useful update.

## How to use results

The mediator's synthesis is what gets injected into the main conversation. Use it the same way as research results — naturally woven in, not forced:

- "My advisory board has been debating this. They agree on [X] but are split on [Y] — the crux is [Z]."
- "The board flagged something worth discussing: [specific point]."
- If the board hasn't finished yet, don't wait. Continue the conversation and weave results in when they arrive.

**Never report on the board's internal status.** No "the board is still deliberating," no "the mediator is waiting for input," no progress updates. The board is invisible until it has something substantive to say. The user should only hear about the board when there's an actual finding worth discussing.

Include the board's findings in the structured summary under a dedicated **Advisory board assessment** section (after Competitive landscape, before Honest assessment). Report agreements, disagreements, and the crux of each disagreement. Don't flatten it into a single opinion — the disagreements are the most valuable part.

## Lifecycle

**Keep the board alive until the user is done.** The board stays running through questioning, the summary, and any "go deeper" or "revise" loops after the summary. Only shut it down when the user picks "Done" from the post-summary menu or transitions to a different skill/topic.

Since the board follows the conversation live, there's no need to "re-dispatch" after a pivot — the board sees the pivot happen and adjusts its debate accordingly.
