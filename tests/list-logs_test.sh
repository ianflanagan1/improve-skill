#!/bin/sh
# Behaviour of skills/ianf-skill-fix/scripts/list-logs.sh. Run with tests/run.sh.
#
# Each test gets its own HOME, so the log directory starts empty.

root=$(cd "$(dirname "$0")/.." && pwd)
script=$root/skills/ianf-skill-fix/scripts/list-logs.sh

setUp() {
    sandbox=$(mktemp -d "${SHUNIT_TMPDIR:-${TMPDIR:-/tmp}}/test.XXXXXX")
    HOME=$sandbox
    export HOME
    logs=$HOME/.local/state/claude-skills/ianf-skill-log-problem
}

tearDown() {
    rm -rf "$sandbox"
}

test_each_log_is_listed_with_its_entries_not_yet_marked_with_a_status() {
    mkdir -p "$logs"
    printf '\n## a\n- skill: ianf-x\n- status: fixed\n\n## b\n- skill: ianf-x\n\n## c\n- skill: ianf-x\n' >"$logs/ianf-x.md"
    printf '\n## a\n- skill: ianf-y\n' >"$logs/ianf-y.md"
    assertEquals "$(printf 'ianf-x  2 open\nianf-y  1 open')" "$(sh "$script")"
}

test_with_no_logs_it_says_so() {
    assertEquals 'No skill problems logged.' "$(sh "$script")"
}

# shellcheck disable=SC1090
. "${SHUNIT2:-$(command -v shunit2)}"
