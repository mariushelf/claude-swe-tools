"""Sphinx configuration.

This file is dropped by the ``update-docs`` skill. Before first use:

1. Set PROJECT_NAME, DIST_NAME, and AUTHOR below (marked ``# EDIT:``).
2. Verify the ``sys.path`` insert points at the directory that contains
   your package (default: ``../../src`` relative to ``docs/source``).
3. The version is looked up from the installed distribution's metadata via
   ``importlib.metadata.version(DIST_NAME)``. If the project is not an
   installable distribution, replace the lookup with a hard-coded string.

Run the build via ``make docs`` at the repo root.
"""

from __future__ import annotations

import os
import sys
from importlib.metadata import PackageNotFoundError, version

# ---------------------------------------------------------------------------
# EDIT: project identity
# ---------------------------------------------------------------------------
PROJECT_NAME = "YOUR PROJECT NAME"  # EDIT: human-readable project title
DIST_NAME = "your-distribution-name"  # EDIT: name on PyPI / in pyproject [project].name
AUTHOR = "YOUR NAME"                # EDIT: author or organisation

# Make the package importable for autodoc/autosummary even when Sphinx is
# invoked outside an editable install (e.g. on Read the Docs or in CI).
# Adjust this path if your package lives somewhere other than ../../src.
sys.path.insert(0, os.path.abspath(os.path.join("..", "..", "src")))

# ---------------------------------------------------------------------------
# Project metadata
# ---------------------------------------------------------------------------
project = PROJECT_NAME
author = AUTHOR

try:
    _pkg_version = version(DIST_NAME)
except PackageNotFoundError:
    _pkg_version = "0.0.0"

release = _pkg_version
version = _pkg_version

# ---------------------------------------------------------------------------
# General configuration
# ---------------------------------------------------------------------------
extensions = [
    "myst_parser",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.doctest",
    "sphinx.ext.napoleon",
    "sphinx.ext.viewcode",
    "sphinx.ext.intersphinx",
    "sphinxcontrib.mermaid",
]

source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

templates_path = ["_templates"]

exclude_patterns = [
    "_build",
    # Sphinx's ``**/README.md`` glob does not match a top-level README, so
    # both patterns are needed to exclude every folder landing page.
    "README.md",
    "**/README.md",
]

root_doc = "index"

# ---------------------------------------------------------------------------
# Napoleon
# ---------------------------------------------------------------------------
# Render docstring ``Attributes`` sections as :ivar: field lists to avoid
# duplicate-object-description warnings when autodoc also documents the
# same attribute from class-body annotations.
napoleon_use_ivar = True

# ---------------------------------------------------------------------------
# MyST
# ---------------------------------------------------------------------------
myst_enable_extensions = [
    "colon_fence",
    "deflist",
]

# Render ```mermaid fenced blocks via sphinxcontrib-mermaid.
myst_fence_as_directive = ["mermaid"]

myst_heading_anchors = 3

# ---------------------------------------------------------------------------
# Autodoc / autosummary
# ---------------------------------------------------------------------------
autosummary_generate = True
autosummary_imported_members = False
autodoc_member_order = "bysource"
autoclass_content = "both"
autodoc_default_options = {
    "members": True,
    "member-order": "bysource",
    "undoc-members": True,
    "show-inheritance": True,
    "exclude-members": "__weakref__,__dict__,__module__",
}

# ---------------------------------------------------------------------------
# Intersphinx
# ---------------------------------------------------------------------------
intersphinx_mapping = {
    "python": ("https://docs.python.org/3", None),
}

# ---------------------------------------------------------------------------
# HTML output
# ---------------------------------------------------------------------------
html_theme = "pydata_sphinx_theme"
html_static_path = ["_static"]
html_title = f"{project} {release}"
