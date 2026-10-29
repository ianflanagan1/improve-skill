#!/bin/sh
# Append a problem entry to a skill's log, under a heading stamped with the current time.
#
# Usage: append-entry.sh <skill> <<'EOF'
#        <one-line summary>
#        - skill: ...
#        EOF
#
# Prints the line to show the user. Exit status: 0 logged, 2 bad usage (nothing written).

set -o nounset

# COUPLED:skill-log-dir. = ianf-skill-fix scripts/list-logs.sh
dir=$HOME/.local/state/claude-skills/ianf-skill-log-problem

[ $# -eq 1 ] || { echo 'usage: append-entry.sh <skill>, with the entry on stdin' >&2; exit 2; }
skill=$1
case $skill in
    '' | */* | .*) echo "append-entry.sh: not a skill name: '$skill'" >&2; exit 2 ;;
esac

entry=$(cat)
summary=$(printf '%s\n' "$entry" | sed -n 1p)
[ -n "$summary" ] || { echo 'append-entry.sh: the first line of the entry must be its summary' >&2; exit 2; }

mkdir -p "$dir"
printf '\n## %s %s\n%s\n' "$(date '+%Y-%m-%d %H:%M')" "$summary" "$(printf '%s\n' "$entry" | sed 1d)" >>"$dir/$skill.md"
echo "🐞 Skill problem logged in ~/${dir#"$HOME"/}/$skill.md; /ianf-skill-fix $skill to fix it."
