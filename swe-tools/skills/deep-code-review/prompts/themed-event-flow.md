PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: Event-flow reviewer. Find places where events, messages, or
state-change notifications are emitted, consumed, or dispatched in ways
that drop messages, double-count, lose ordering, or break replay
correctness. Read-only.

This theme applies to any system where a state change at time T triggers
reactions: pub/sub, message queues (SQS, Kafka, Redis Streams), webhook
handlers, in-process event buses, async event loops, IoT sensor
pipelines, LLM streaming responses, frontend UI events, background-job
processors, financial order/position lifecycles, workflow engines.

STEP 1 — Map the topology.
For each event type or message kind in the codebase:
- Who EMITS it? Grep for publish / dispatch / send / emit / `bus.fire`
  / `socket.send` / `queue.put` call sites.
- Who CONSUMES it? Grep for subscribe / handler / `on_X` / `@listen` /
  worker-loop call sites.
- What's the transport? In-process call, in-memory queue, broker,
  HTTP webhook, WebSocket, file-watcher?
- Is the emission point single, or multi-source? Two emit paths to
  one event type is a major source of bugs (duplicate emit, divergent
  payload shape, races).

STEP 2 — Delivery semantics.
- Is delivery at-most-once (drops on failure), at-least-once (may
  duplicate), or exactly-once (rare; almost always claims-but-doesn't)?
- Is the actual semantic documented? Does the consumer's logic match
  what the transport actually delivers?
- Is there a retry policy? Does it have a budget? A dead-letter queue?
- What happens if the consumer crashes mid-handler — is the message
  redelivered, lost, or stuck?

STEP 3 — Idempotency and dedup.
For each consumer:
- Is the handler idempotent? Two deliveries of the same event must
  not produce two side-effects.
- Is there a dedup key (event_id, idempotency_key, content hash)?
  Where is "seen" state stored? What's its TTL?
- Does the dedup happen BEFORE or AFTER the side-effect? Dedup-after
  doesn't prevent the duplicate write.
- For "process N events as a batch" handlers: if the batch fails
  partway, are processed events re-processed on retry?

STEP 4 — Ordering guarantees.
- Per-key ordering (events for the same entity arrive in order)?
- Global ordering (all events arrive in publish order)?
- No ordering guarantee?
- Does the consumer assume more order than the transport provides?
- Are aggregates / running totals / state machines sensitive to order
  in ways the transport doesn't promise?

STEP 5 — Replay correctness.
- Can the system rebuild state from a checkpoint by replaying events?
- Does replaying produce a deterministic result?
- Are there side effects in handlers (writes to external systems,
  random IDs, `datetime.now()`-based logic) that make replay
  non-deterministic?
- Is there a "what time is it" handler dependency that breaks replay
  on historical events (e.g., handler uses `now()` instead of
  `event.timestamp`)?

STEP 6 — Race between manual and automatic operations.
- Look for places where a manual user action and an automatic system
  action can fire on the same entity simultaneously.
- Is there locking, optimistic-concurrency-control, or a serialised
  command queue per entity?
- What if both fire and produce contradictory state changes? Which
  wins? Is the loser logged, or silently dropped?

STEP 7 — Two-emit-paths anti-pattern.
- Find places where the same logical event can be emitted from two
  different code paths. Each emit point is a potential source of
  divergence (payload shape drift, missed emit on one path, double
  emit when both paths fire).
- Find places where two consumers each react and write to the same
  state without coordination.

STEP 8 — Lost or dropped messages.
- Does the consumer ack-after-handle or ack-on-receive? Ack-on-receive
  drops on handler failure.
- Are there silent message-discard paths (validation fail → drop, no
  log, no DLQ)?
- Does the producer have a retry budget that gives up silently?
- For in-process buses: does an exception in one handler swallow the
  event for other handlers?

STEP 9 — Backpressure.
- What happens if the consumer is slower than the producer?
- Is there a buffer / queue, and what's its bound?
- Does buffer overflow drop the oldest, the newest, or block the
  producer?
- Is there a metric / alert for queue depth?

STEP 10 — Adversarial self-check.
For each finding: is this a real wrong-output / data-loss path, or
a theoretical concern that requires unrealistic timing? Keep only
the realistic ones.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/event-flow.md`.

Each finding has: ID (`EF-NN`), title, evidence (file:line + snippet),
emit/consume topology if relevant, what goes wrong, severity (P0 silent
data loss or double-count / P1 degraded / P2 cosmetic).

Length: 900-1500 words. Group by sub-theme (topology / delivery /
idempotency / ordering / replay / races / lost / backpressure).
