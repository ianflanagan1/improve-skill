---
name: ianf-skill-fix
description: Fix a skill from the problems logged by /ianf-skill-log-problem. Finds the skill's source, pins each problem down as a failing behaviour test, changes the skill, and shows the before and after for review. Never commits.
argument-hint: [skill name] [path to its source]
disable-model-invocation: true
model: opus
effort: medium
context: fork
agent: general-purpose
background: false
allowed-tools: Bash(sh *scripts/list-logs.sh*), Read(~/.local/state/claude-skills/ianf-skill-log-problem/**), Edit(~/.local/state/claude-skills/ianf-skill-log-problem/**)
---

# Fix a skill

Turn logged problems with a skill into tested changes to its source, for the user to review and commit.

## Gather (`/ianf-skill-fix $ARGUMENTS`)

Problem logs in `~/.local/state/claude-skills/ianf-skill-log-problem/`, with their number of open entries:

```
!`sh "${CLAUDE_SKILL_DIR}/scripts/list-logs.sh"`
```

- `No skill problems logged.`, or no log with open entries: reply `➖ No skill problems logged.` and stop.
- `$ARGUMENTS` names the skill, optionally followed by the path to its source. If it names none and only one log has open entries, use that one. If several have, reply `⚠️ Several skills have open problems: <names>.`, end with `👉 Run /ianf-skill-fix <name> for one of them.`, and stop.
- Read that log, `<skill>.md` in that directory. Entries marked `- status:` are already handled; skip them.

## Find the source

1. Look for the installed skill, first match wins: `.claude/skills/<name>` in the current project, `~/.claude/skills/<name>`, then plugin installs (`find ~/.claude/plugins -type d -path '*/skills/<name>'`).
2. Resolve symlinks (`cd -P <dir> && pwd`) and find its repository (`git -C <dir> rev-parse --show-toplevel`).
3. If the skill is a plugin install under `~/.claude/plugins`, it is a copy: don't edit it. Use the path from `$ARGUMENTS` if it gave one. Otherwise read `repository` from its `plugin.json`, reply `⚠️ <name> is installed as a plugin, a copy that can't be fixed in place.`, end with `👉 Run /ianf-skill-fix <name> <path to a local clone of <repository>>.`, and stop.
4. Note any uncommitted changes in that repository (`git status --short`). Leave them alone, and keep your changes separate from them.
5. Find how the repository runs its tests and lint: README, `CLAUDE.md`, `devbox.json` scripts, `Makefile`, `package.json`. Run the tests once before changing anything, so you know what already fails.

## Fix each entry

Classify it first:
- **Script**: a script crashed, gave wrong output or lacked a behaviour.
- **Instruction**: SKILL.md or a reference file was wrong, unclear or missing a case.
- **Not the skill**: the cause was the user's repository or environment. Mark it and move on.
- **Can't reproduce**: say so and mark it; don't guess at a fix.

### Script

1. State the behaviour the script should have, as one sentence about inputs and outcomes, not about the incident: "a file ending without a newline is staged exactly", not "fix the bug from Tuesday".
2. Find the test that covers that behaviour. If there is one, work out why it passed and strengthen it. If there isn't, add a test named for the behaviour, next to the tests for related behaviour.
3. Run it and confirm it fails, for the reason in the log. If it passes, the behaviour isn't what broke: look again.
4. Change the script until it passes. Then run the whole suite and the lint.

Never weaken, skip or delete a test to make a change pass.

### Instruction

1. Write down the situation from the log and what the current wording led to.
2. Change the smallest amount of text that makes the right action clear. Keep the file's voice and structure.
3. If the repository has evals or scenario tests for its skills, add a case for the situation. Otherwise show, in the report, how the new wording leads to the right action.
4. If the fix is a deterministic procedure, prefer moving it into a script with tests over adding prose.

## Mark entries

Add a line under each entry you handled:

```
- status: <fixed (uncommitted) | not the skill: <reason> | can't reproduce> <YYYY-MM-DD>
```

## Report

For each entry: the problem in one line, its class, and for fixes the behaviour now asserted, the test result before (failing, with its message) and after (passing), and the files changed. Then the full test and lint result, and `git diff --stat` for the source repository.

End by telling the user the changes are uncommitted in `<repository>`, for review and `/ianf-commit` there. Don't commit, push or edit anything outside that repository and the log.
