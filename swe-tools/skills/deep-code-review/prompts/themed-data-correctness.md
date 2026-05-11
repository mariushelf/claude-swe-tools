PROJECT_CONTEXT: $PROJECT_CONTEXT
SCOPE: $SCOPE
EXCLUDES: $EXCLUDES
SUSPECT_INVENTORY (from discovery): $SUSPECT_INVENTORY

> The inventory is a confirmed-leads list from a 600-word survey, **not a
> coverage limit**. You must generate findings beyond it. The inventory's
> omissions are often the most valuable scenarios to find. Treat it as your
> starting point, not your boundary.

YOUR ROLE: Data-correctness reviewer. Find places where data crossing a
system boundary (file, network, database, queue, user input, FFI) loses
information, gains incorrect information, or silently changes shape.
Read-only.

The bar for a finding: "data on one side of the boundary is silently
not equal to data on the other side, in a way that affects correctness."

STEP 1 — Map the I/O boundaries.
For each boundary in the codebase:
- File reads / writes (CSV, JSON, Parquet, YAML, pickle, custom).
- Network calls (HTTP / gRPC / WebSocket / SSE).
- Database access (ORM, raw SQL, document store).
- Queue / cache ops (Redis, Kafka, in-memory).
- Process boundaries (subprocess stdin/stdout, IPC, env vars).
- Foreign-function calls (C extension, FFI, WASM bridge).
- User input (CLI args, form fields, API payloads, browser localStorage).

STEP 2 — Schema validation at the boundary.
For each boundary:
- Is incoming data validated (Pydantic / JSON Schema / Zod / custom)?
- What happens if validation fails: raise, log-and-drop, log-and-default,
  silent-coerce?
- Is the validation strict-by-default (extra fields rejected) or lax
  (extra fields silently passed through, possibly poisoning downstream)?
- Are required fields enforced, or does `None` / empty-string slip
  through as a default?

STEP 3 — Type-coercion traps.
- A string that looks like a number (`"01"`, `"1.0"`, `"1e10"`) parsed
  differently by `int()` vs `JSON.parse` vs the database driver.
- A boolean serialised as `"true"`/`"false"` string vs 0/1 int vs
  native True/False — all three may coexist in one codebase.
- Datetime serialised in one timezone, deserialised in another.
- Null vs NaN vs empty-string vs absent-key conflated.
- Unicode normalisation (NFC vs NFD) at the boundary.
- Strings that look numeric but have leading-zero / locale separators.

STEP 4 — Round-trip correctness.
For each round-trippable boundary (write then read, serialize then
deserialize):
- Does `parse(serialize(x)) == x` hold for all valid `x`?
- What types lose information on round-trip: floats (precision),
  Decimals (cast to float), NaN, Inf, dataclasses with default
  factories, datetimes with microsecond precision, sets (ordering),
  tuples (cast to list)?
- Is there a test for round-trip equivalence?
- For pickle / shelf / similar: what happens when the class
  definition changes?

STEP 5 — Pipeline-step idempotency.
For each multi-step pipeline:
- Can step N be re-run safely if it failed mid-way? Or does it leave
  partial state that corrupts the next attempt?
- Does the pipeline have a checkpoint / resume mechanism, or does it
  always restart from scratch?
- If the pipeline writes to multiple sinks, what happens if one
  succeeds and another fails?
- For ETL: is the load step transactional, or can it half-write?

STEP 6 — Unique-key and identity.
- Is there a single source of truth for entity identity, or do multiple
  systems each generate their own IDs?
- Is the ID a UUID (collision-safe), an autoincrement (race-prone),
  or a content-hash (deterministic only if input is canonical)?
- Are there places where the system trusts an externally-supplied ID
  without verification?
- For deduplication: is the dedup key stable across re-serialisation?

STEP 7 — Encoding and locale.
- File reads without explicit encoding (defaults vary across OS).
- String comparisons that depend on locale (`upper()`, sort order).
- Number formatting / parsing that depends on locale (`,` vs `.`).
- Date parsing that depends on system locale.
- Path separator assumptions (`/` vs `\`).

STEP 8 — Schema evolution.
- If the on-disk format changes, what happens to old data?
- Is there a version field, migration script, or schema registry?
- Is the format declared anywhere (Pydantic class, Avro / JSON
  Schema, Parquet metadata, protobuf), or is it implicit?
- Does the writer emit a version, and does the reader gate on it?

STEP 9 — Adversarial self-check.
For each finding: produce a concrete input that triggers the data
corruption / loss. If you can't, downgrade severity.

OUTPUT: Write `docs/reviews/<DATE>-deep-review/data-correctness.md`.

Each finding has: ID (`DAT-NN`), title, evidence (file:line + snippet),
boundary involved, what changes, severity (P0 silent data corruption /
P1 degraded / P2 stylistic).

Length: 900-1500 words. Group by sub-theme (validation / coercion /
round-trip / idempotency / identity / encoding / evolution).
