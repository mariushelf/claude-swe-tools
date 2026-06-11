PROJECT_CONTEXT: $PROJECT_CONTEXT
FINDING: $FINDING          (the DOC_AUDIT.md entry driving this page)
PAGE_VARIANT: $PAGE_VARIANT  (getting_started | code_style | testing | ci_cd | git_workflow | operations | guide:<topic>)
TARGET_PATH: $TARGET_PATH  (docs/source-root-absolute path)

YOUR ROLE: Author of one how-to page. Read-then-write. Generate a single
`.md` file at `$TARGET_PATH`. Do not create any other files.

Follow `assets/meta/voice.md` rules 1–7. Exception: how-to steps may
use imperative forms ("run `make test`", "open `pyproject.toml`"). Even
then, prefer the imperative over "you can".

Follow `assets/meta/writing_documentation.md` for the procedural steps.

---

## Page shape

Title the page with the reader's goal, not the subsystem name.
Good: "Running the test suite". Poor: "Testing".

Lead with the task — what the page enables — in one sentence. Do not
open with background or motivation.

Structure body content as ordered steps when the reader must follow
a sequence; use a flat list when order is not significant. Prefer
imperative verbs: "run", "add", "open", "set".

Derive every command, flag, make target, and config option from the
actual repository. Cite the source by name — the file or make target — not a
`file:line`. Do not invent defaults or flags that cannot be verified.

---

## Sources to consult for each variant

Before writing, read the relevant files. Cite them by name (path or make
target), not by line number.

| Variant | Primary sources |
|---|---|
| `getting_started` | `README.md`, `pyproject.toml`, `.devcontainer/`, `docs/source/` skeleton |
| `code_style` | `pyproject.toml` (ruff/flake8/mypy sections), `.pre-commit-config.yaml`, `Makefile` |
| `testing` | `Makefile` (`test` target), `pyproject.toml` (`[tool.pytest]`), `tests/` layout |
| `ci_cd` | `.github/workflows/*.yml` or equivalent CI config |
| `git_workflow` | `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` — each only if present |
| `operations` | Deploy configs, Dockerfiles, CI/CD deploy jobs, settings modules, monitoring configs |
| `guide:<topic>` | The module, adapter, or subsystem the guide addresses |

For `git_workflow`: branch-protection rules, required reviews, and other
server-side repository settings cannot be verified from the repository
contents. Never state them as fact. If the workflow depends on them,
say so and note that they are configured server-side and not verifiable
from the repository.

For `operations`: the audience is operators — people deploying, configuring,
and monitoring the system in production. Cover deployment, configuration and
environment variables, monitoring and alerting, and runbooks for common
incidents, in whatever subset the repository actually evidences. Every claim
is still grounded in current source (deploy configs, Dockerfiles, CI manifests,
settings modules), cited by file or symbol name; omit any topic the repository
contains no evidence for.

---

## Authoring rules

- Ground every factual claim in current source, cited by module or file name —
  not `file:line`.
- Describe what the code does today, in present tense.
- Label designed-but-unbuilt steps with a self-contained `{caution}`
  admonition that states inline what is unbuilt and why, citing the
  evidence or its absence (one or two sentences; no links to plan or
  ledger files):

  ```{caution}
  Designed but not implemented: <what>. <Where the design appears and
  why the code does not yet do this>.
  ```

- Cross-reference in-tree pages with the MyST `{doc}` role and
  source-root-absolute docnames.
- Do not include a troubleshooting section unless `$FINDING` specifically
  calls for one and the failure modes can be grounded in the codebase.
- Do not pad with background that belongs on a concept page; link to it
  instead: `` {doc}`/concepts/...` explains the underlying model ``.

OUTPUT: Write the completed `.md` file to `$TARGET_PATH`. No other
files. No summary prose outside the file.
