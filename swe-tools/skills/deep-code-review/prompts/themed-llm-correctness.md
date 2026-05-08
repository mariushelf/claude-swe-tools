PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: LLM-correctness reviewer. Find places where calls to language
models can silently produce wrong output, leak data, blow up cost, or
break the consumer's contract. Applies to any code that calls an LLM
(OpenAI, Anthropic, Azure OpenAI, AWS Bedrock, local models, LiteLLM,
LangChain, LlamaIndex, vLLM, etc.). Read-only.

The bar for a finding: "the user (or downstream code) trusts the LLM's
output to mean X, but in a realistic case the output silently means Y,
or costs N× more than expected, or leaks something."

STEP 1 — Map the LLM call sites.
For each `client.chat.completions.create` / `messages.create` /
`completion(...)` / equivalent:
- What's the prompt template? Where does user input enter it?
- What's the expected output: free text, JSON, structured-output schema,
  tool-call, streaming?
- Who consumes the output, and what shape do they expect?
- Is the model identifier a constant, a config field, or hardcoded?

STEP 2 — Prompt injection.
- Is user input concatenated into the prompt without delimiters or
  sanitisation?
- Is the system prompt overridable by user input ("ignore previous
  instructions" attack)?
- Are tool descriptions / function names trusted to come from the
  developer, but could be influenced by retrieved content (RAG)?
- Is there a defence: input length cap, content filter, marker tokens
  (e.g., `<UNTRUSTED>...</UNTRUSTED>`), separate-message structure?
- For agentic systems: can a tool's output influence the next prompt
  in a way that hijacks the agent loop?

STEP 3 — Output schema drift.
- Code expects strict JSON. Is JSON-mode / structured-outputs flag
  set, or does the code just hope?
- Is there a retry on parse failure, with backoff and a budget?
- Does the parser accept slightly malformed output (markdown fence
  ```` ```json ````, prose preface, trailing comma) silently or
  strictly?
- For structured-output schemas: is the schema versioned in code?
  What happens if the model returns extra fields, or omits optional
  ones?
- For tool-calling: are tool arguments validated against the declared
  schema before execution?

STEP 4 — Determinism and reproducibility.
- Even with `temperature=0`, the output is not bit-deterministic
  across API calls. Does the code treat the output as deterministic
  (cache key, primary key, hash input, idempotency token)?
- Is there a `seed` parameter set? Is the user told that seed
  doesn't guarantee determinism on most APIs?
- Are evaluation suites stable across runs, or do they fluctuate?

STEP 5 — Token-limit handling.
- Is the input length measured (in tokens, not characters) before
  the call?
- What happens at the context-window boundary: truncate-old,
  truncate-new, fail, silently overflow?
- For `max_tokens`: is it set high enough to allow the expected
  output? What does the consumer do if the response stops mid-JSON
  (truncated)?
- Is `finish_reason` / `stop_reason` checked for `"length"` vs
  `"stop"` vs `"tool_use"`?

STEP 6 — Cost / loop blow-up.
- Is there a per-request token budget cap?
- Is there a per-session / per-user / per-day spend cap?
- For agentic / chained-call systems: a depth budget, a step cap, a
  cycle detector?
- Retry-on-error: can it amplify spend exponentially (especially for
  large prompts)?
- For RAG: is the retrieved context bounded, or can a malicious
  query pull in the entire corpus?

STEP 7 — Hallucinated identifiers leaking downstream.
- The LLM returns a `customer_id`, `sku`, `file_path`, `function_name`,
  `endpoint_url`, `SQL fragment`, `shell command`. Is this validated
  before use, or trusted?
- For tool-calling: are tool args validated, or passed through to the
  tool implementation?
- For SQL / shell command generation: is there an injection-safe path,
  or is the LLM trusted to produce safe syntax?
- For URL / file-path generation: is there path-traversal or SSRF
  protection?

STEP 8 — Rate-limit and error handling.
- Is 429 handled with exponential backoff and jitter?
- Is 5xx silently retried, or surfaced?
- Does the error path return a default (empty string, `"I don't know"`,
  empty list) that a downstream consumer treats as a valid answer?
- Is there observability: request ID logged, latency, token counts,
  cost per call?

STEP 9 — Prompt-template drift.
- Are prompt strings duplicated across files? Edits in one place may
  not propagate.
- Is there a single registry / module / file for prompts, or are
  they inlined at call sites?
- Are prompts versioned in any form (git tag, prompt-id field,
  hash-in-config)?

STEP 10 — Privacy and logging.
- Is PII / sensitive content in prompts logged at INFO / DEBUG?
- Are prompts and responses sent to a third-party observability tool
  (LangSmith, Helicone, etc.) without user consent?
- Does the user have a way to opt-out of logging, or to purge logs?
- Are API keys / tokens visible in tracebacks or error messages?

STEP 11 — Adversarial self-check.
For each finding: is this a real silent-wrong / cost / leak issue,
or theoretical? Keep only the realistic ones.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/llm-correctness.md`.

Each finding has: ID (`LLM-NN`), title, evidence (file:line + snippet),
attack / failure scenario, severity (P0 silent wrong-output, prompt
injection, or unbounded cost / P1 degraded / P2 stylistic).

Length: 900-1500 words. Group by sub-theme (injection / schema /
determinism / tokens / cost / hallucinated-IDs / errors / prompts /
privacy).
