# ---------------------------------------------------------------------------
# Documentation targets — merged into the project Makefile by the
# update-docs skill. Assumes Sphinx source is at docs/source/ and output
# lands at docs/build/.
#
# This header also serves as the merge sentinel: the scaffolding step looks
# for it in the project Makefile to detect that the block was already merged
# (idempotency). Keep the header text intact when editing.
# ---------------------------------------------------------------------------

# Command prefix that runs tools inside the project environment. These
# targets are opinionated on uv (the `uv sync` calls below assume it) and on
# a src/ layout (docs-live watches src/); RUN stays a variable only so
# one-off invocations can override it.
RUN ?= uv run

.PHONY: docs docs-strict docs-linkcheck docs-live test-docs docs-doctest clean-docs

# Build HTML documentation.
docs:
	uv sync --group docs
	$(RUN) sphinx-build -a -b html docs/source docs/build/html
	@echo "Open docs/build/html/index.html"

# Strict build: fail on any warning.
# Use this in CI to catch broken cross-references, orphaned pages, and
# autodoc surprises before they reach the main branch.
docs-strict:
	uv sync --group docs
	$(RUN) sphinx-build -W --keep-going -a -b html docs/source docs/build/html

# Check external links. Kept separate from docs-strict because it depends on
# the network and is therefore flaky in CI and useless offline.
docs-linkcheck:
	uv sync --group docs
	$(RUN) sphinx-build -a -b linkcheck docs/source docs/build/linkcheck

# Live-reload mode: rebuild on file change. Watches both docs source and src.
docs-live:
	uv sync --group docs
	$(RUN) sphinx-autobuild -a -b html docs/source docs/build/html \
		--watch src \
		--open-browser

# Run the docs drift-tripwire test suite.
test-docs:
	$(RUN) pytest tests/docs

# Run Sphinx doctest builder to verify code examples in docs.
docs-doctest:
	uv sync --group docs
	$(RUN) sphinx-build -a -b doctest docs/source docs/build/doctest

# Remove build artefacts and auto-generated API stubs. The _apidoc path must
# match the ``:toctree:`` directory in docs/source/reference/python-api.md.
clean-docs:
	rm -rf docs/build docs/source/reference/_apidoc
