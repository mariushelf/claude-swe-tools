#!/usr/bin/env bash
set -euo pipefail

# Usage: vault-search.sh <vault-path> [--type TYPE] [--tag TAG] [--project PROJECT] [KEYWORD...]
# Examples:
#   vault-search.sh ~/claude-vault sqlalchemy
#   vault-search.sh ~/claude-vault --type gotcha --tag tech/python
#   vault-search.sh ~/claude-vault --project my-app session

VAULT_PATH="${1:?vault path required}"
shift

TYPE=""
TAG=""
PROJECT=""
KEYWORDS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type)    TYPE="$2"; shift 2 ;;
        --tag)     TAG="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        *)         KEYWORDS+=("$1"); shift ;;
    esac
done

# Build search path
SEARCH_PATH="$VAULT_PATH"
if [ -n "$PROJECT" ]; then
    SEARCH_PATH="$VAULT_PATH/projects/$PROJECT"
fi

# Find matching markdown files (exclude _index.md)
while IFS= read -r -d '' file; do
    # Extract frontmatter
    FRONTMATTER=$(awk '/^---$/{if(c++)exit;next}c' "$file")

    # Filter by type
    if [ -n "$TYPE" ]; then
        echo "$FRONTMATTER" | grep -q "^type: .*$TYPE" || continue
    fi

    # Filter by tag
    if [ -n "$TAG" ]; then
        echo "$FRONTMATTER" | grep -q "  - $TAG" || continue
    fi

    # Filter by keywords (search title + first 20 lines of content)
    if [ ${#KEYWORDS[@]} -gt 0 ]; then
        SEARCHABLE=$(echo "$FRONTMATTER"; head -20 "$file")
        MATCH=true
        for kw in "${KEYWORDS[@]}"; do
            echo "$SEARCHABLE" | grep -qi "$kw" || { MATCH=false; break; }
        done
        $MATCH || continue
    fi

    # Extract display fields
    TITLE=$(echo "$FRONTMATTER" | grep "^title:" | sed 's/^title: *"\?\([^"]*\)"\?/\1/')
    DATE=$(echo "$FRONTMATTER" | grep "^date:" | sed 's/^date: *//')
    FTYPE=$(echo "$FRONTMATTER" | grep "^type:" | sed 's/^type: *//')
    REL_PATH="${file#$VAULT_PATH/}"

    # First content line (skip frontmatter and heading)
    PREVIEW=$(awk '/^---$/{if(c++)d=1;next}d && /^[^#]/ && NF{print;exit}' "$file")

    echo "[$FTYPE] $REL_PATH"
    echo "  Title: $TITLE | Date: $DATE"
    [ -n "$PREVIEW" ] && echo "  $PREVIEW"
    echo ""
done < <(find "$SEARCH_PATH" -name '*.md' ! -name '_index.md' -print0)
