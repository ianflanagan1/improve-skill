#!/bin/sh
# Checks across the skills' SKILL.md files. Run with tests/run.sh.

root=$(cd "$(dirname "$0")/.." && pwd)

# loading_commands skill: each command the skill runs as it loads, one per line, with
# ${CLAUDE_SKILL_DIR} filled in and "a; b" split into separate commands.
loading_commands() {
    # shellcheck disable=SC2016
    sed -n 's/^!`\(.*\)`$/\1/p' "$root/skills/$1/SKILL.md" |
        sed -e "s,\${CLAUDE_SKILL_DIR},/home/u/.claude/skills/$1,g" -e 's/ 2>&1//g' -e 's/; /\
/g'
}

# allows skill command: whether a Bash rule in the skill's allowed-tools matches the command, as
# Claude Code matches it: "*" matches anything, quotes included, and a legacy "prefix:*" matches
# the prefix alone or followed by a space.
allows() {
    command=$2
    rules=$(sed -n 's/^allowed-tools: //p' "$root/skills/$1/SKILL.md" | sed 's/, /\
/g' | sed -n 's/^Bash(\(.*\))$/\1/p')
    while IFS= read -r rule; do
        [ -n "$rule" ] || continue
        case $rule in
            *:\*) prefix=${rule%:\*}; set -- "$prefix" "$prefix *" ;;
            *) set -- "$rule" ;;
        esac
        for glob; do
            # shellcheck disable=SC2254  # the rule is the pattern
            case $command in $glob) return 0 ;; esac
        done
    done <<EOF
$rules
EOF
    return 1
}

test_every_command_a_skill_runs_as_it_loads_is_in_its_allowed_tools() {
    for skill in "$root"/skills/*/; do
        skill=$(basename "$skill")
        while IFS= read -r command; do
            [ -n "$command" ] || continue
            allows "$skill" "$command" || fail "$skill does not allow: $command"
        done <<EOF
$(loading_commands "$skill")
EOF
    done
}

test_every_skill_states_whether_agents_can_invoke_it() {
    for f in "$root"/skills/*/SKILL.md; do
        grep --extended-regexp --quiet '^disable-model-invocation: (true|false)$' "$f" ||
            fail "$(basename "$(dirname "$f")") has no disable-model-invocation: true or false"
    done
}

# shellcheck disable=SC1090
. "${SHUNIT2:-$(command -v shunit2)}"
