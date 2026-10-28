#!/bin/sh
# Behaviour of scripts/skill-conventions-gate.py. Run with tests/run.sh.
#
# Each test gets its own TMPDIR, so the gate's per-session state starts empty.

root=$(cd "$(dirname "$0")/.." && pwd)
gate=$root/scripts/skill-conventions-gate.py
conventions=$root/skill-conventions.md

setUp() {
    sandbox=$(mktemp -d "${SHUNIT_TMPDIR:-${TMPDIR:-/tmp}}/test.XXXXXX")
    sandbox=$(cd "$sandbox" && pwd -P)
    TMPDIR=$sandbox/tmp
    export TMPDIR
    mkdir -p "$TMPDIR" "$sandbox/project/skills/hello/references"
    : >"$sandbox/project/skills/hello/SKILL.md"
}

tearDown() {
    rm -rf "$sandbox"
}

# hook session tool input-json: run the gate on a PreToolUse event, printing its output.
hook() {
    printf '{"session_id":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s}' "$1" "$2" "$3" \
        | python3 -I "$gate"
}

# write session path: the gate's output for the Write tool creating path.
write() { hook "$1" Write "{\"file_path\":\"$2\",\"content\":\"x\"}"; }

# edit session path: the gate's output for the Edit tool changing path.
edit() { hook "$1" Edit "{\"file_path\":\"$2\",\"old_string\":\"a\",\"new_string\":\"b\"}"; }

# bash session command: the gate's output for the Bash tool running command.
bash_tool() { hook "$1" Bash "{\"command\":\"$2\"}"; }

# skill session name: the gate's output for the Skill tool invoking name.
skill() { hook "$1" Skill "{\"skill\":\"$2\"}"; }

assertRefused() { assertContains "$1" '"permissionDecision": "deny"'; }
assertAllowed() { assertEquals '' "$1"; }

# --- What counts as changing a skill

test_writing_a_skill_md_anywhere_is_refused_with_the_conventions_in_the_reason() {
    out=$(write s1 /any/where/at/all/SKILL.md)
    assertRefused "$out"
    printf '%s' "$out" | python3 -c '
import json, sys
reason = json.load(sys.stdin)["hookSpecificOutput"]["permissionDecisionReason"]
sys.exit(open(sys.argv[1]).read().strip() not in reason)' "$conventions"
    assertTrue 'the reason holds the whole conventions file' $?
}

test_editing_a_file_inside_a_skills_directory_is_refused() {
    assertRefused "$(edit s1 "$sandbox/project/skills/hello/references/notes.md")"
}

test_writing_a_file_outside_any_skill_is_allowed() {
    assertAllowed "$(write s1 "$sandbox/project/README.md")"
}

test_invoking_skill_creator_is_refused() {
    assertRefused "$(skill s1 anthropic-skills:skill-creator)"
}

test_invoking_another_skill_is_allowed() {
    assertAllowed "$(skill s1 commit)"
}

test_a_bash_command_that_writes_a_skill_md_is_refused() {
    assertRefused "$(bash_tool s1 "sed -i '' s/a/b/ skills/hello/SKILL.md")"
    assertRefused "$(bash_tool s2 'cat >skills/hello/SKILL.md <<EOF')"
    assertRefused "$(bash_tool s3 'printf x | tee -a SKILL.md')"
    assertRefused "$(bash_tool s4 'mv draft.md skills/hello/SKILL.md')"
}

test_a_bash_command_that_only_reads_a_skill_md_is_allowed() {
    assertAllowed "$(bash_tool s1 'cat skills/hello/SKILL.md')"
    assertAllowed "$(bash_tool s1 'grep -n name skills/*/SKILL.md 2>/dev/null | head')"
    assertAllowed "$(bash_tool s1 'sed -n 1,5p SKILL.md >/dev/null 2>&1')"
}

test_a_bash_command_not_naming_a_skill_md_is_allowed() {
    assertAllowed "$(bash_tool s1 'echo hi >notes.txt')"
}

# The JSON strings below hold \n escapes, which the hook decodes into a multi-line command.

test_a_heredoc_body_naming_a_skill_md_does_not_count_as_writing_it() {
    assertAllowed "$(bash_tool s1 "cat >>log.md <<'EOF'\n- did: mv draft.md skills/hello/SKILL.md\nEOF")"
}

test_a_heredoc_written_into_a_skill_md_is_refused() {
    assertRefused "$(bash_tool s1 "cat >skills/hello/SKILL.md <<'EOF'\nhello\nEOF")"
}

test_a_command_after_a_heredoc_still_counts() {
    assertRefused "$(bash_tool s1 "cat >notes.md <<'EOF'\nx\nEOF\nmv notes.md SKILL.md")"
}

test_a_here_string_is_not_taken_for_a_heredoc() {
    assertRefused "$(bash_tool s1 "cat <<<hi\nmv draft.md SKILL.md")"
}

# --- Once per session

test_the_second_skill_change_in_a_session_is_allowed() {
    write s1 /a/SKILL.md >/dev/null
    assertAllowed "$(write s1 /b/SKILL.md)"
    assertAllowed "$(skill s1 anthropic-skills:skill-creator)"
}

test_a_new_session_is_refused_again() {
    write s1 /a/SKILL.md >/dev/null
    assertRefused "$(write s2 /a/SKILL.md)"
}

test_allowed_calls_do_not_use_up_the_sessions_refusal() {
    bash_tool s1 'cat SKILL.md' >/dev/null
    write s1 "$sandbox/project/README.md" >/dev/null
    assertRefused "$(write s1 /a/SKILL.md)"
}

# --- Robustness

test_input_that_is_not_json_is_allowed() {
    assertAllowed "$(echo 'not json' | python3 -I "$gate" 2>/dev/null)"
    assertEquals 0 "$(echo 'not json' | python3 -I "$gate" >/dev/null 2>&1; echo $?)"
}

test_the_conventions_file_exists() {
    assertTrue "[ -s '$conventions' ]"
}

# shellcheck disable=SC1090
. "${SHUNIT2:-$(command -v shunit2)}"
