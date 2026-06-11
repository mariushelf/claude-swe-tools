PROJECT_CONTEXT: $PROJECT_CONTEXT
FINDING: $FINDING          (the DOC_AUDIT.md entry driving this page)
PAGE_VARIANT: $PAGE_VARIANT  (glossary | faq | rest-api | python-api)
TARGET_PATH: $TARGET_PATH  (docs/source-root-absolute path)

YOUR ROLE: Author of one reference page. Read-then-write. Generate a single
`.md` file at `$TARGET_PATH`. Do not create any other files.

Follow `assets/meta/voice.md` rules 1–7 in every sentence. Reference pages
are optimized for lookup, not for reading start to finish. Exhaustive and
scannable is the goal.

Follow `assets/meta/writing_documentation.md` for the procedural steps.

---

## Page shapes

### glossary (ubiquitous language)

List every domain term that appears in the codebase or the architecture docs.
For each term:

- **Term** — one precise definition grounded in the code (`file:line`).
- **Avoid** — one to three synonyms or near-synonyms that appear in the wild
  and are *not* used in this codebase. Naming the avoided forms prevents
  newcomers from importing them.

Order the terms alphabetically. Do not group them by theme — readers scan, not
browse. Do not define terms by restating them ("a cache is a thing that caches
data"). Extract definitions from the code: the docstring, the class invariants,
the type signature.

Do not invent terms that do not appear in the codebase or the design documents.

### faq

Collect questions whose answers are (a) non-obvious and (b) grounded in the
current source. Each entry is a second-level heading phrased as a question,
followed by a direct answer in one to three paragraphs.

Sources for questions: `$FINDING` (if it cites specific confusion points),
existing `{caution}` admonitions in the docs, edge cases in the code, and
common misunderstandings found in issues or PR comments. Do not invent
questions; derive them from evidence.

Every answer must cite `file:line`. If a question cannot be answered from
current source, omit it rather than guessing.

### rest-api

Produce this page only if the project exposes an HTTP API. If `$FINDING`
requests a rest-api page but no route definitions exist in the source,
do not fabricate one — state in your output that no HTTP API was found
and write nothing.

Adapt to whatever framework the project uses (FastAPI, Flask, Django,
or another). Derive all routes from the source — route decorators, URL
config, blueprint registrations — never from a live server.

Lead with a compact table of all endpoints, one row per endpoint:

| Method | Path | Summary |
|--------|------|---------|

Derive the table from the route definitions directly (`file:line` for each
route). Do not copy from existing prose — re-derive from source.

After the table, provide for each endpoint:

- **Request** — path and query parameters, their types, and whether they are
  required. A `curl` example using realistic placeholder values.
- **Response** — the success HTTP status and a minimal JSON example of the
  response envelope. For fields whose semantics are non-obvious, one sentence.
- **Errors** — the error envelope shape (one example) and the documented error
  codes. If the framework generates a machine-readable API reference (e.g.
  FastAPI's OpenAPI `/docs`), do not duplicate per-field semantics that it
  already covers — point there instead:

  ```{note}
  Full per-field semantics, enum values, and validation constraints are
  documented in the generated OpenAPI reference at `/docs`.
  ```

  Include such a note only when the source shows the project actually
  serves a generated reference; otherwise document the error codes here.

Cite the route definitions and the request/response model or serializer
definitions with `file:line`.

### python-api

Use an `autosummary` directive to generate the API reference from the package's
public symbols. Do not enumerate every symbol by hand — the directive keeps the
page in sync automatically.

```{eval-rst}
.. autosummary::
   :toctree: _apidoc
   :recursive:

   your_package
```

Replace `your_package` with the actual top-level package name (`file:line` for
where the package's `__init__.py` declares `__all__` or its public surface).

Add a brief introduction (two to four sentences) explaining what the package
exposes and which submodules are part of the public API versus internal
implementation. Ground every claim in `file:line`.

If the package uses `__all__` to declare its public surface, cite it:
`src/your_package/__init__.py:N`. If it does not, flag the gap:

```{caution}
This package does not define `__all__`, so the public API boundary is
not declared in code (`src/your_package/__init__.py` has no `__all__`).
The autosummary above covers all top-level names; internal names
(prefixed `_`) are excluded.
```

---

## Authoring rules

- Ground every factual claim in a `file:line` reference. If a claim cannot be
  grounded, do not make it.
- Describe what the code does today, in present tense.
- If the codebase or the finding mentions designed-but-unbuilt behavior,
  label it with a self-contained `{caution}` admonition that states
  inline what is unbuilt and why, citing the evidence or its absence
  (one or two sentences; no links to plan or ledger files):

  ```{caution}
  Designed but not implemented: <what>. <Where the design appears and
  why the code does not yet do this>.
  ```

- Cross-reference in-tree pages with the MyST `{doc}` role and
  source-root-absolute docnames:
  `` {doc}`/concepts/cache` `` (not a relative path, not a URL).
- Do not add a page-level `## Contents` or `## Overview` heading; start
  directly with the first substantive content.
- For the glossary: every term must appear somewhere in the codebase or
  design documents. Do not define a term that has no code evidence.
- For the rest-api: never fabricate an endpoint, parameter, or status code.
  Every item in every table comes from a `file:line` read.

OUTPUT: Write the completed `.md` file to `$TARGET_PATH`. No other
files. No summary prose outside the file.
