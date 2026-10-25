# improve-skill

A Claude Code hook and skill for keeping skills right: the hook holds new and changed skills to your conventions, and the skill fixes skills from the problems they log while running.

## Skill conventions

`skills/ianf-improve-skill/references/skill-conventions.md` holds how you want skills written, for example the status-line emojis a skill's reply starts with. Edit it to add your own.

The `PreToolUse` hook (`scripts/skill-conventions-gate.py`) puts it in front of Claude before the first skill change in each session, however the change is made. It refuses that first call with the file's text as the reason; Claude applies it and retries, and the rest of the session's calls pass. The text goes in the reason rather than a path, so Claude needs no permission to read a file outside its project. Nothing is added to prompts that don't touch skills.

A call changes a skill when it is:
- a Write or Edit on a `SKILL.md` anywhere on disk, or on any file under a directory holding one;
- the Skill tool invoking skill-creator;
- a Bash command that names `SKILL.md` and looks like it writes (a redirect, `tee`, `sed -i`, `mv` and so on), not counting the bodies of its heredocs, which are data. This one is a heuristic.

Anything the hook can't parse passes, so a broken hook never blocks work. It needs `python3` (the macOS system one is enough).

## Fixing skills from logged problems

1. **Claude reports.** When any skill goes wrong (one of its scripts fails, an instruction can't be followed, Claude has to work around it, or you correct its result), Claude appends an entry to `~/.claude/skill-feedback/<skill>.md` and ends the run with one line pointing here. The steps are in `skills/ianf-improve-skill/references/reporting-problems.md`; one rule in your global `CLAUDE.md` turns them on for every skill, so skills don't need to change.
2. **You run `/ianf-improve-skill <skill>`.** It finds the skill's source (following symlinks to its repository) and works through the open entries. For a script problem it states the behaviour the script should have, writes or strengthens a test for that behaviour, confirms the test fails, and changes the script until the whole suite passes. For an instruction problem it makes the smallest wording change and explains why it works.
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

`/ianf-improve-skill` adds `- status: ...` under each entry it handles.

## Install

Clone to `~/projects/claude/improve-skill`, then link the skill, which gives `/ianf-improve-skill` and the stable path the rule below reads from:

```sh
ln -s ~/projects/claude/improve-skill/skills/ianf-improve-skill ~/.claude/skills/ianf-improve-skill
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
          "command": "python3 -I \"$HOME/projects/claude/improve-skill/scripts/skill-conventions-gate.py\""
        }
      ]
    }
  ]
}
```

Point it at the script in the clone rather than a link to it: the script finds the conventions relative to its own path.

Then add to `~/.claude/CLAUDE.md`:

```markdown
## Skill problems

When a skill goes wrong itself (a script of its fails, an instruction can't be followed, you work around it, or I correct a result its instructions led to), follow `~/.claude/skills/ianf-improve-skill/references/reporting-problems.md`. Skip this if that file doesn't exist.
```

## Development

```sh
devbox run test   # shunit2
devbox run lint   # shellcheck
```
