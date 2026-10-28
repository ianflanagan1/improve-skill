# Skill conventions

How the user wants skills written. Apply these whenever you create or change a skill, by any route: by hand, with skill-creator, or with another skill. Where they differ from skill-creator's defaults, these win. Where the skill's own repository consistently does something different, follow the repository. If `~/projects/claude/skill-patterns/` exists, it holds named designs for how skills work together, such as a private sub-skill, listed in its README.

## Status line

A skill's reply starts with one status line when its run ends in one of these outcomes. Write each in SKILL.md as the exact text in backticks: the emoji, a space, and a short sentence ending in a full stop.

This section defines the scheme. The command-line tools built on [cli-kit](https://github.com/ianflanagan1/cli-kit) implement it, so a skill that runs one of those commands can repeat the command's status line as its own.

| Emoji | Outcome | Example |
|---|---|---|
| ✅ | The operation changed state as asked | `✅ Committed.` |
| 🛑 | It stopped part way, after changing some state | `🛑 Stopped.` |
| ❌ | It ran and failed | `❌ Commit failed.` |
| ⚠️ | A precondition wasn't met, so nothing was tried | `⚠️ Uncommitted changes.` |
| ➖ | There was nothing to do | `➖ Nothing staged.` |

- Use only the outcomes the skill can have. ✅, 🛑 and ❌ are for skills that change state (commit, push, publish, edit files). A skill that only produces text, such as one suggesting a commit message, has no ✅ line: its output is the result. ⚠️ and ➖ fit any skill's early exits.
- After ✅: the result in as few lines as it takes (new commits, a URL), and nothing else.
- After 🛑: what was done, what's left, and how to undo or resume.
- After ❌: the error, unchanged, in a fenced `text` code block, then one short line on the cause and the fix you propose. Don't apply the fix unless the skill says to.
- After ⚠️: the precondition that failed and what the user should do about it.
- After ➖: nothing. Make no tool calls once you know there's nothing to do.

## Permissions

A skill runs with no one to approve a command when it's called headless (`claude -p`, CI, a script). Auto mode and approval prompts hide a missing rule interactively, so don't take an interactive run as proof.

- Every command a skill runs as it loads (each `` !`…` `` line) must be allowed by its `allowed-tools`, every part of it: in `sh "${CLAUDE_SKILL_DIR}/scripts/x.sh" 2>&1; echo "exit $?"`, both the `sh` and the `echo`. Otherwise the skill doesn't load, and a headless run reports success with an empty result.
- Write rules for the skill's own scripts as `Bash(sh *scripts/<name>.sh*)`, which matches the path quoted or not. `Bash(sh */scripts/<name>.sh:*)` doesn't match a quoted path. Allow the exit line with `Bash(echo "exit $?")`.
- Also allow the commands the skill tells Claude to run, such as `Bash(git commit:*)`.
- A load-time `cat` of a file that resolves outside the session's working directories is blocked whatever the rules say, also when the path goes through a symlink, such as a skill installed as a link to its repository. Rules can't fix that; adding the repository to `permissions.additionalDirectories` does.
- Where the skill's repository has tests, add one that checks every load-time command against `allowed-tools`. Before relying on a skill headless, run it once with `claude -p` in default mode, not auto, and check that `permission_denials` is empty.

## Naming

Every skill's name starts with `ianf-`, so it can't collide with built-in skills or anyone else's: the `name:` in SKILL.md, its folder under `skills/` and its link in `~/.claude/skills/` are all `ianf-<name>`, and other skills and READMEs call it `/ianf-<name>`. Repositories and hooks don't take the prefix.

## Installing

Skills are standalone, not plugins: a repository has no `.claude-plugin/`, even when it holds several related skills. Each skill is linked into place:

```sh
ln -s ~/projects/claude/<repo>/skills/ianf-<name> ~/.claude/skills/ianf-<name>
```

A hook goes in the `hooks` section of `~/.claude/settings.json`, as a command that runs the script from the repository by its path under `$HOME`. Don't link the script itself: a script that finds its own files relative to its path looks in the link's folder.

## Repository

A repository of skills or hooks lives in `~/projects/claude/<repo>/`, and its GitHub repository has the same bare name, with no `ianf-` or `claude-` prefix: the owner already namespaces it. Its description says it is a Claude Code skill (or skills, or hook), and it has the topics `claude-code` and `claude-skills`.

- Publish with `github publish <dir>`; the repository takes the folder's name.
- To rename one, use `github rename <dir> <new-name>`, rename the folder to match, then fix the links that name it.
