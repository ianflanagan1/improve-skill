# Reporting a problem with a skill

The protocol `/ianf-improve-skill` reads. Any skill is covered; skills don't need to mention it. Follow it when something went wrong with a skill itself:
- a script failed, crashed or printed output you couldn't use
- an instruction was wrong, unclear, contradictory or impossible to follow here
- you had to work around the skill to finish
- the user corrected a result the skill's instructions led you to

Problems in the user's repository (a failing test, a hook rejecting their code) are not skill problems.

## Log it

Append one entry to `~/.claude/skill-feedback/<skill name>.md` in one Bash call, creating the directory if needed. Use a quoted heredoc so nothing is expanded:

```sh
mkdir -p ~/.claude/skill-feedback && cat >>~/.claude/skill-feedback/<skill name>.md <<'EOF'

## <YYYY-MM-DD HH:MM> <one-line summary>
- skill: <skill name>, step: <section of SKILL.md>
- did: <the command you ran, or the instruction you followed>
- got: <exit status and the relevant output, trimmed to what shows the problem>
- expected: <what should have happened>
- instead: <what you did to finish, or "stopped">
EOF
```

Keep it to what reproduces the problem: the shape of the input (a file with no trailing newline, a path with spaces), not the user's code or secrets. Don't fix the skill yourself.

## Tell the user

After the skill's normal output, add one line, even where the skill says to print nothing else:

`Skill issue logged in ~/.claude/skill-feedback/<skill name>.md; /ianf-improve-skill <skill name> to fix it.`
