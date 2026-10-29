#!/bin/sh
# Behaviour of skills/ianf-skill-log-problem/scripts/append-entry.sh. Run with tests/run.sh.
#
# Each test gets its own HOME, so the log directory starts empty.

root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/ianf-skill-log-problem/scripts/append-entry.sh

setUp() {
    sandbox=$(mktemp --directory "${SHUNIT_TMPDIR:-${TMPDIR:-/tmp}}/test.XXXXXX")
    HOME=$sandbox
    export HOME
    logs=$HOME/.local/state/claude-skills/ianf-skill-log-problem
}

tearDown() {
    rm -rf "$sandbox"
}

# append skill: run the script for skill with a two-field entry on stdin.
append() {
    sh "$script" "$1" <<'EOF'
count.sh always fails
- skill: ianf-x, step: Count
- got: exit 64
EOF
}

test_an_entry_is_appended_under_a_heading_stamped_with_the_current_date_and_time() {
    before=$(date '+%Y-%m-%d %H:%M')
    append ianf-x >/dev/null
    after=$(date '+%Y-%m-%d %H:%M')
    heading=$(sed -n 2p "$logs/ianf-x.md")
    case $heading in
        "## $before count.sh always fails" | "## $after count.sh always fails") ;;
        *) fail "unexpected heading: $heading" ;;
    esac
    assertEquals '- skill: ianf-x, step: Count' "$(sed -n 3p "$logs/ianf-x.md")"
    assertEquals '- got: exit 64' "$(sed -n 4p "$logs/ianf-x.md")"
}

test_the_log_directory_is_created_when_missing() {
    append ianf-x >/dev/null
    assertTrue "[ -f '$logs/ianf-x.md' ]"
}

test_a_second_entry_is_added_after_the_first() {
    append ianf-x >/dev/null
    append ianf-x >/dev/null
    assertEquals 2 "$(grep --count '^## ' "$logs/ianf-x.md")"
}

test_it_prints_the_line_that_tells_the_user_where_the_problem_is_logged() {
    assertEquals \
        '🐞 Skill problem logged in ~/.local/state/claude-skills/ianf-skill-log-problem/ianf-x.md; /ianf-skill-fix ianf-x to fix it.' \
        "$(append ianf-x)"
}

test_a_skill_name_that_is_not_a_plain_name_is_refused_and_nothing_is_written() {
    for bad in '' ../x a/b .hidden; do
        append "$bad" >/dev/null 2>&1
        assertEquals "exit for '$bad'" 2 $?
    done
    assertFalse 'nothing written' "[ -d '$logs' ]"
}

test_an_entry_without_a_summary_line_is_refused() {
    printf '\n- skill: ianf-x\n' | sh "$script" ianf-x >/dev/null 2>&1
    assertEquals 2 $?
    assertFalse 'nothing written' "[ -d '$logs' ]"
}

# shellcheck disable=SC1090
. "${SHUNIT2:-$(command -v shunit2)}"
