#!/usr/bin/env bash
set -euo pipefail

# Usage: index-update.sh <vault-path> <index-file> <section> <entry>
# Example: index-update.sh ~/claude-vault projects/foo/_index.md "ADRs" "- [[0001-2026-03-24-title]] — summary"

VAULT_PATH="${1:?vault path required}"
INDEX_FILE="${2:?index file required}"
SECTION="${3:?section name required}"
ENTRY="${4:?entry required}"

LOCKFILE="$VAULT_PATH/.vault-lock"
INDEX_PATH="$VAULT_PATH/$INDEX_FILE"

# Acquire lock (timeout 30s, stale lock detection)
if [ -f "$LOCKFILE" ]; then
    LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || stat -f %m "$LOCKFILE" 2>/dev/null || echo 0) ))
    if [ "$LOCK_AGE" -gt 30 ]; then
        rm -f "$LOCKFILE"
    fi
fi

exec 200>"$LOCKFILE"
flock -w 10 200 || { echo "ERROR: Could not acquire lock" >&2; exit 1; }

if [ ! -f "$INDEX_PATH" ]; then
    echo "ERROR: Index file not found: $INDEX_PATH" >&2
    exit 1
fi

# Find the section and append entry after it
# Uses awk to insert the entry after the last non-empty line in the section
awk -v section="## $SECTION" -v entry="$ENTRY" '
    $0 == section { in_section=1; print; next }
    in_section && /^## / { if (!printed) { print entry; print ""; printed=1 } in_section=0 }
    in_section && /^_No .* yet\._$/ { print entry; printed=1; next }
    { print }
    END { if (in_section && !printed) print entry }
' "$INDEX_PATH" > "$INDEX_PATH.tmp" && mv "$INDEX_PATH.tmp" "$INDEX_PATH"

# Release lock
flock -u 200
