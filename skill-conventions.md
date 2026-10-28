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

## Next step

When a run leaves the user a step to take, such as running another skill, the reply ends with one line starting 👉: the step, in the words the user would type, then what it will do. Write it in SKILL.md as the exact text in backticks, with placeholders for the details, such as `👉 Run /ianf-tune-rules in this session: it adds <n> evidence lines to the guides without asking, …`.

- At most one 👉 line, and always last.
- Only for a step the workflow needs. Advice the user may ignore stays in the body.
- When a skill usually ends with a 👉 line but this run leaves nothing for that step, end instead with a ➖ line saying so, such as `➖ Nothing for /ianf-tune-rules to record.`, so the missing step reads as decided, not forgotten.

## Permissions

A skill runs with no one to approve a command when it's called headless (`claude -p`, CI, a script). Auto mode and approval prompts hide a missing rule interactively, so don't take an interactive run as proof.

- Every command a skill runs as it loads (each `` !`…` `` line) must be allowed by its `allowed-tools`, every part of it: in `sh "${CLAUDE_SKILL_DIR}/scripts/x.sh" 2>&1; echo "exit $?"`, both the `sh` and the `echo`. Otherwise the skill doesn't load, and a headless run reports success with an empty result.
- Write rules for the skill's own scripts as `Bash(sh *scripts/<name>.sh*)`, which matches the path quoted or not. `Bash(sh */scripts/<name>.sh:*)` doesn't match a quoted path. Allow the exit line with `Bash(echo "exit $?")`.
- Also allow the commands the skill tells Claude to run, such as `Bash(git commit:*)`.
- A load-time `cat` of a file that resolves outside the session's working directories is blocked whatever the rules say, also when the path goes through a symlink, such as a skill installed as a link to its repository. Rules can't fix that; adding the repository to `permissions.additionalDirectories` does.
- Where the skill's repository has tests, add one that checks every load-time command against `allowed-tools`. Before relying on a skill headless, run it once with `claude -p` in default mode, not auto, and check that `permission_denials` is empty.

## Naming

Every skill's name starts with `ianf-`, so it can't collide with built-in skills or anyone else's: the `name:` in SKILL.md, its folder under `skills/` and its link in `~/.claude/skills/` are all `ianf-<name>`, and other skills and READMEs call it `/ianf-<name>`. Repositories and hooks don't take the prefix.

## Invocation

Decide whether agents can invoke the skill, and lean hard towards **cannot**: set `disable-model-invocation: true`, so it runs only when the user types its name. Always write the field, even when it matches Claude Code's default, so every skill shows the decision. Let agents invoke it (`disable-model-invocation: false`) only when it has to start without the user typing its name: when it reacts to something Claude meets mid-task, such as `/ianf-coupled-tags` before editing a tagged line, or to requests from people who won't know its name, such as `/ianf-report-problem`. Then its description must name the situations that should trigger it.

Whenever you create a skill or change this setting, report the choice on a line of its own, as one of these exact texts, followed by a one-line reason, so the user can overrule it:

- `🤖 Agents can invoke this.`
- `🔒 Agents cannot invoke this.`

Talk to the user in these terms, never as `disable-model-invocation` being true or false, which reads backwards.

## Storing files

A skill keeps the files it writes for later runs (logs, caches, records of what it did) in `~/.local/state/claude-skills/<skill>/`, named by its full `ianf-` name, and nowhere else outside the project it works on. A script that writes there sets the path once, in a variable at its top.

Never in `~/.claude/`: Claude Code owns that directory, and a future version may claim a name there. When Claude's permissions are tightened, allowing writes to `~/.claude/` would also allow changes to its settings, hooks and instructions, while one rule such as `Edit(~/.local/state/claude-skills/**)` (and the same path under the sandbox's `allowWrite`) covers every skill's state and nothing else. `~/.local/state` is where the XDG convention puts such state, on Linux and macOS alike.

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
