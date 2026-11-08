# ADR-014: own change-reviewer agent for change reviews

- Status: Accepted
- Date: 2026-11-07

## Context

Step 4 of the change workflow is a review of the result against the proposal by a
fresh-context subagent. Without a fixed reviewer, each session wrote its own review prompt and
picked the model, so reviews of similar changes checked different things, and the session that
wrote the code decided what its reviewer looked at.

## Decision

1. Reviews use the project agent `change-reviewer` (`.claude/agents/change-reviewer.md`), on
   Sonnet, read-only, for every change size. It has no `Edit` or `Write` tool; it keeps `Bash`
   for `fvm`, limited by a `PreToolUse` hook in its frontmatter
   (`.claude/hooks/review-bash.sh`) to the review diff tool, the two checkers, tests, analyze
   and a format check, one command per call, so it can neither run git directly nor write
   through the shell. The hook applies only to this agent's calls.
2. It always runs a fixed checklist in two passes: code (correctness for this stack) and
   conformance (proposal, spec, tests by requirement ID, docs, strings, guarded files).
3. The main session may pass parameters that only add to the review; it cannot turn off a
   checklist item. The main session fixes; the reviewer only reports.

## Alternatives considered

- The built-in `/code-review` and plugin reviewers: rejected. The project should not depend on
  external review tools, and they know nothing of requirement IDs, the spec or our approval
  rules.
- A review prompt written by each session: rejected, because reviews are not comparable and
  the reviewed session chooses what is checked.
- Allow rules for read-only git commands (`git diff*`, `git log*`, `git show*`): rejected.
  Permission rules match only the start of a command, so they also allow `git log -p` or a
  diff without paths, which can print the committed Firebase config files that are never read;
  without allow rules, every review asks the user several times.

## Consequences

- Reviews are comparable and cheaper (Sonnet).
- The code pass starts weaker than `/code-review`, which runs several reviewers. Every bug a
  review misses becomes a checklist item in the agent file.
- The agent reads git only through `tool/review_diff.dart`, which builds every git command
  itself and never prints never-read files, so reviews run without permission prompts.
- Claude Code runs the agent's frontmatter hook only after the workspace trust dialog is
  accepted for the project folder; until then the Bash limits rest on the agent's
  instructions alone. The hook needs `jq` and blocks every command when it is missing.
