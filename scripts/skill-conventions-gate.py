"""PreToolUse hook: before the first skill change in a session, send Claude to the skill conventions.

Reads the hook event as JSON on stdin. If the tool call creates or changes a skill, and it is the
first such call in this session, it prints a "deny" decision whose reason holds the conventions
file's text; Claude applies it and retries, and later calls in the session pass. The text goes in
the reason, not a path, so Claude needs no permission to read a file outside its project. Anything else, and
any input it can't parse, passes silently (exit 0, no output), so a broken hook never blocks work.

A tool call changes a skill when it is:
- Write, Edit, MultiEdit or NotebookEdit on a SKILL.md, or on any file in a directory under one
  that holds a SKILL.md;
- the Skill tool invoking skill-creator;
- a Bash command naming SKILL.md that looks like it writes (a redirect, tee, sed -i, mv, ...).

Per-session state is a marker file in $TMPDIR/claude-skill-conventions/.

Works on Python 3.9 (the macOS system python3).
"""

import json
import os
import re
import sys
import tempfile

CONVENTIONS = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "skills", "ianf-improve-skill", "references", "skill-conventions.md")
)

FILE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}

# A redirect into a file (not 2>&1 or >/dev/null), or a command that writes or moves files.
BASH_WRITES = re.compile(
    r"""(?<![0-9&>])>>?(?!&|\s*/dev/null)
      | \btee\b
      | \bsed\b[^|;&]*\s-i
      | \bperl\b[^|;&]*\s-\w*i
      | \b(mv|cp|ln|rm|touch|truncate|patch)\b
      | \bgit\s+(apply|checkout|restore)\b""",
    re.VERBOSE,
)


def in_skill(path):
    if os.path.basename(path) == "SKILL.md":
        return True
    d = os.path.dirname(os.path.abspath(path))
    while True:
        if os.path.isfile(os.path.join(d, "SKILL.md")):
            return True
        parent = os.path.dirname(d)
        if parent == d:
            return False
        d = parent


def changes_skill(tool, tool_input):
    if tool in FILE_TOOLS:
        path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
        return bool(path) and in_skill(path)
    if tool == "Skill":
        return str(tool_input.get("skill", "")).split(":")[-1] == "skill-creator"
    if tool == "Bash":
        command = str(tool_input.get("command", ""))
        return "SKILL.md" in command and BASH_WRITES.search(command) is not None
    return False


def first_in_session(session):
    state = os.path.join(tempfile.gettempdir(), "claude-skill-conventions")
    os.makedirs(state, exist_ok=True)
    marker = os.path.join(state, re.sub(r"[^A-Za-z0-9_-]", "_", session) or "unknown")
    try:
        with open(marker, "x"):
            return True
    except FileExistsError:
        return False


def main():
    try:
        event = json.load(sys.stdin)
        tool_input = event.get("tool_input") or {}
        if not changes_skill(event.get("tool_name", ""), tool_input):
            return
        if not first_in_session(str(event.get("session_id", ""))):
            return
    except Exception:
        return
    try:
        with open(CONVENTIONS, encoding="utf-8") as f:
            conventions = f.read().strip()
    except OSError:
        conventions = "(could not read " + CONVENTIONS + ")"
    reason = (
        "Before creating or changing a skill, apply these conventions to this change and any others "
        "to skills in this session, then retry this call.\n\n" + conventions
    )
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))


if __name__ == "__main__":
    main()
