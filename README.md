# improve-skill

A Claude Code hook and skill for keeping skills right: the hook holds new and changed skills to your conventions, and the skill fixes skills from the problems they log while running.

## Skill conventions

`skill-conventions.md` holds how you want skills written, for example the status-line emojis a skill's reply starts with. Edit it to add your own. It sits at the top of the repository, not inside a skill, because everything here that writes or changes skills shares it.

The `PreToolUse` hook (`scripts/skill-conventions-gate.py`) puts it in front of Claude before the first skill change in each session, however the change is made. It refuses that first call with the file's text as the reason; Claude applies it and retries, and the rest of the session's calls pass. The text goes in the reason rather than a path, so Claude needs no permission to read a file outside its project. Nothing is added to prompts that don't touch skills.

A call changes a skill when it is:
- a Write or Edit on a `SKILL.md` anywhere on disk, or on any file under a directory holding one;
- the Skill tool invoking skill-creator;
- a Bash command that names `SKILL.md` and looks like it writes (a redirect, `tee`, `sed -i`, `mv` and so on), not counting the bodies of its heredocs, which are data. This one is a heuristic.

Anything the hook can't parse passes, so a broken hook never blocks work. It runs on the Python 3.13 in this repository's devbox, so run `devbox install` in the clone before adding the hook.

## Fixing skills from logged problems

1. **The problem is logged.** When any skill goes wrong (one of its scripts fails, an instruction can't be followed, Claude has to work around it, or you correct its result), Claude runs `/ianf-skill-log-problem`, which appends an entry, stamped with the date and time, to `~/.local/state/claude-skills/ianf-skill-log-problem/<skill>.md`, and ends the run with a line starting 🐞 that says where. Claude can invoke it itself, and its description names those moments; one line in your global `CLAUDE.md` makes it reliable mid-task. Skills don't need to mention it. You can also run `/ianf-skill-log-problem <skill> <what went wrong>` yourself when you notice a problem.
2. **You run `/ianf-skill-fix <skill>`.** It finds the skill's source (following symlinks to its repository) and works through the open entries. For a script problem it states the behaviour the script should have, writes or strengthens a test for that behaviour, confirms the test fails, and changes the script until the whole suite passes. For an instruction problem it makes the smallest wording change and explains why it works.
3. **You review and commit.** It marks each entry in the log and reports the before and after. It never commits; the changes are left in the skill's repository for you.

## Log entry format

```
## 2026-10-08 14:03 stage-lines.sh rejected a path with a tab
- skill: commit, step: Stage
- did: sh .../stage-lines.sh 'a<TAB>b' 2
- got: exit 2, No such file in the index or working tree
- expected: line 2 staged
- instead: staged the whole file with git add
```

`/ianf-skill-fix` adds `- status: ...` under each entry it handles.

## Install

Clone to `~/projects/claude/skill-authoring`, then link the skills:

```sh
for s in ~/projects/claude/skill-authoring/skills/*/; do
    ln -s "${s%/}" ~/.claude/skills/"$(basename "$s")"
done
```

Add the hook to `~/.claude/settings.json`. It runs straight from the clone, so changes to it apply from the next call:

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Write|Edit|MultiEdit|NotebookEdit|Bash|Skill",
      "hooks": [
        {
          "type": "command",
          "command": "\"$HOME/projects/claude/skill-authoring/.devbox/nix/profile/default/bin/python3\" -I \"$HOME/projects/claude/skill-authoring/scripts/skill-conventions-gate.py\""
        }
      ]
    }
  ]
}
```

Point it at the script in the clone rather than a link to it: the script finds the conventions relative to its own path. The command names the devbox's interpreter by path rather than through `devbox run`, which would add its startup time to every tool call.

Then add to `~/.claude/CLAUDE.md`:

```markdown
## Skill problems

When a skill goes wrong, run `/ianf-skill-log-problem`.
```

## Development

```sh
devbox run test   # shunit2
devbox run lint   # shellcheck
```
