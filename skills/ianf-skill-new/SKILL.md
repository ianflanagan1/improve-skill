---
name: ianf-skill-new
description: Create a Claude Code skill to the user's conventions, in its own repository under ~/projects/claude or an existing one, test-first where it has scripts, linked into ~/.claude/skills with its install steps in the README. Optionally publishes the repository to GitHub. Never commits.
argument-hint: <what the skill should do>
disable-model-invocation: true
allowed-tools: Bash(ls ~/projects/claude), Bash(git init:*), Bash(ln -s:*), Bash(github publish:*), Bash(github view:*), Bash(github edit:*)
---

# Create a skill

Build one skill for `$ARGUMENTS`, from the first idea to a linked, working install, for the user to review and commit.

## 1. Read the conventions

Read `~/projects/claude/skill-authoring/skill-conventions.md` with the Read tool, before planning anything. Apply it to every step below. If `~/projects/claude/skill-patterns/README.md` exists, read that index too. Where a pattern may fit, read its file, use it, and say which design you chose. Don't invoke skill-creator: where its advice differs from the conventions, the conventions win, and this skill covers the rest.

## 2. Settle what it is

Propose these together and wait for the user to confirm or change them:

- **Name:** `ianf-<name>`, kebab-case, naming what the skill does.
- **Description:** what it does and when to use it, in the third person. For a skill Claude may invoke itself, the description is all Claude sees when deciding, so it names the situations that should trigger it.
- **Invocation:** whether agents can invoke it, decided as the conventions' Invocation section says. Show it as its `🤖 Agents can invoke this.` or `🔒 Agents cannot invoke this.` line, with the reason.
- **Repository:** an existing repository in `~/projects/claude/` when the skill belongs with the skills there (list them with `ls ~/projects/claude`), otherwise a new one named as the conventions' Repository section says.
- **Outcomes:** the status lines its runs can end in, from the conventions' table.

If `~/.claude/skills/ianf-<name>` or the skill's folder already exists, reply `⚠️ ianf-<name> already exists.` with where it is, and stop.

## 3. Lay out the repository

For a new repository, `git init` it in `~/projects/claude/<repo>/` and copy the shape of `~/projects/claude/skill-authoring`: an MIT `LICENSE` in the user's name and year, a `README.md`, and, when the skill has scripts, a `devbox.json` with `test` and `lint` scripts and a `tests/run.sh`. For an existing repository, follow what it already does, and note any uncommitted changes in it so yours stay separate.

## 4. Write it, test-first where there are scripts

Put each deterministic procedure in a script under `skills/ianf-<name>/scripts/` rather than in prose, and keep SKILL.md for the parts that need judgement.

For each script behaviour: write a test named for the behaviour in `tests/<script>_test.sh`, run it and see it fail, then write the script until it passes. Add the test the Permissions section asks for, checking every load-time command against `allowed-tools`.

Write SKILL.md last: frontmatter, a `#` title, one line on what the skill is for, numbered steps, and a Report section giving each status line as exact text.

Run the repository's tests and lint until both pass. If they still fail and you can't see why, reply `🛑 Stopped.` with the failing output, the files written so far, and how to remove them (the folder, and the link if made).

## 5. Install

1. Link the skill as the conventions' Installing section says.
2. Add an Install section to the README with the same `ln -s` line, plus any hook or settings entry the skill needs, so it can be installed on another machine.
3. If the skill needs a change to `~/.claude/settings.json` (a hook, a permission, an `additionalDirectories` entry), show the user the change and make it only once they agree.

## 6. Publish

Only if the user asked to publish. Otherwise stop here and offer it.

Publishing needs at least one commit; if there is none, stop and ask the user to commit first. Then run `github publish <dir>`, and add the topics with `github edit <repo> --add-topic claude-code --add-topic claude-skills`. If the description `github view <repo>` prints doesn't say it is a Claude Code skill, propose one and set it with `github edit <repo> --description "<text>"` once the user agrees. Use the `github` tool for every GitHub step, never `gh` directly.

If a publish command fails, reply `❌ Publish failed.` as the conventions describe. The skill itself is still created and linked; say so.

## Report

Start with `✅ Created ianf-<name>.`, and on the next line the skill's `🤖 Agents can invoke this.` or `🔒 Agents cannot invoke this.` line with its one-line reason. Then give:

- the skill's folder and its link in `~/.claude/skills/`;
- the behaviours tested, and the test and lint result;
- the GitHub URL, if published;
- what's left for the user: reviewing and committing (`/ianf-commit` in the repository), and publishing if they haven't.

Don't commit. Leave the changes in the repository for review.
