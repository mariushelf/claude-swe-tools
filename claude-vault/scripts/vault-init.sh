#!/usr/bin/env bash
set -euo pipefail

VAULT_PATH="${1:-$HOME/claude-vault}"

if [ -d "$VAULT_PATH" ]; then
    echo "ERROR: Vault already exists at $VAULT_PATH" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"

# Create directory structure
mkdir -p "$VAULT_PATH"/{projects,knowledge/{patterns,gotchas,solutions}}

# Copy templates
cp "$TEMPLATES/vault-index.md" "$VAULT_PATH/_index.md"
cp -r "$TEMPLATES/.obsidian" "$VAULT_PATH/.obsidian"

# Create .gitignore
cat > "$VAULT_PATH/.gitignore" << 'GITIGNORE'
.vault-lock
.obsidian/workspace*.json
.obsidian/graph.json
.obsidian/backlink.json
GITIGNORE

# Initialize git
cd "$VAULT_PATH"
git init
git add _index.md .obsidian/ .gitignore projects/ knowledge/
git commit -m "init: initialize claude vault"

echo "Vault initialized at $VAULT_PATH"
