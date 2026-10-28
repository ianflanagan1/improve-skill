#!/bin/sh
# List each skill with a problem log, and how many of its entries have no status yet.
#
# Usage: list-logs.sh
#
# Prints "<skill>  <n> open" per log, or "No skill problems logged." when there are none.

set -u

# COUPLED:skill-log-dir. = ianf-skill-log-problem scripts/append-entry.sh
dir=$HOME/.local/state/claude-skills/ianf-skill-log-problem

found=0
for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    found=1
    entries=$(grep -c '^## ' "$f")
    handled=$(grep -c '^- status:' "$f")
    printf '%s  %s open\n' "$(basename "$f" .md)" $((entries - handled))
done
[ "$found" = 1 ] || echo 'No skill problems logged.'
