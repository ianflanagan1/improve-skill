---
name: ianf-skill-log-problem
description: Log a problem with a skill, for /ianf-skill-fix to fix later. Use as soon as a skill goes wrong, in any skill, mid-task: one of its scripts fails, crashes or prints output you can't use; an instruction is wrong, unclear, contradictory or impossible to follow here; you work around the skill to finish; or the user corrects a result its instructions led to. Also when the user describes a problem with a skill.
argument-hint: [skill name] [what went wrong]
disable-model-invocation: false
model: inherit
allowed-tools: Bash(sh *scripts/append-entry.sh*)
---

# Log a problem with a skill

Record what went wrong with a skill so `/ianf-skill-fix` can fix it later. Any skill is covered; skills don't need to mention this one. Don't fix the skill yourself.

Problems in the user's repository (a failing test, a hook rejecting their code) are not skill problems.

## Gather

- **Run by an agent mid-task:** the skill and the problem are the ones just met. Finish or stop the task as the problem allows, then log it.
- **Run by the user (`/ianf-skill-log-problem $ARGUMENTS`):** take the skill and the problem from `$ARGUMENTS` and the conversation. If either is unclear, ask.

## Log it

Run the script once, with the entry in a quoted heredoc so nothing is expanded. Its first line is the summary; the script adds the date and time.

```sh
sh "${CLAUDE_SKILL_DIR}/scripts/append-entry.sh" <skill name> <<'EOF'
<one-line summary>
- skill: <skill name>, step: <section of SKILL.md>
- did: <the command you ran, or the instruction you followed>
- got: <exit status and the relevant output, trimmed to what shows the problem>
- expected: <what should have happened>
- instead: <what you did to finish, or "stopped">
EOF
```

Keep it to what reproduces the problem: the shape of the input (a file with no trailing newline, a path with spaces), not the user's code or secrets.

## Report

The script prints the line to show the user, starting `🐞 Skill problem logged in`.

- **Run mid-task:** end your reply with that line, after the task's normal output, even where the other skill says to print nothing else.
- **Run by the user:** reply `✅ Problem logged.`, then that line.
