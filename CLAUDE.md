# claude-swe-tools

Claude Code plugin marketplace with the `swe-tools` and `grilling` plugins.
See [README.md](README.md).

## Code Graph

The graph in `graphify-out/` is rebuilt by git hooks after commit, checkout,
merge, and rebase. It is AST only and can lag a moment behind. Each worktree
has its own graph, and it is not committed.

- Query it before broad searches: `graphify query "<question>"`,
  `graphify explain "<node>"`, `graphify path "A" "B"`, and
  `graphify-out/GRAPH_REPORT.md` for an overview.
- `pre-commit install --allow-missing-config` installs all hook types,
  including these. The flag keeps checkouts of old commits without a config
  working.
- If the graph is missing, run `sh scripts/graphify-update.sh`. Do not call
  `graphify update .` directly: it overwrites the global graphify skill files.
- The script runs graphify through `uvx` and pins the version in the script.
  Bump the pin by hand.
