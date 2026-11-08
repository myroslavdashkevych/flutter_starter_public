#!/usr/bin/env bash
# PreToolUse hook for Bash, set in the frontmatter of the change-reviewer agent
# (.claude/agents/change-reviewer.md). Allows only the commands a review needs and
# blocks everything else, including direct git and shell writes. Calls from other
# agents and from the main session pass untouched. Reads the hook JSON on stdin;
# exit 2 blocks the call and shows stderr to the agent.

# Read the hook JSON before any exit: leaving stdin unread can fail the writer
# with a broken pipe. `read` is a builtin, so it works without any PATH, and it
# reads descriptor 0 itself, so it also works when stdin is a socket (on Linux,
# reopening /dev/stdin fails for one). It returns 1 at the end of the input.
IFS= read -r -d '' input || true

if ! command -v jq >/dev/null 2>&1; then
  echo 'Blocked: jq is not installed, so the reviewer command check cannot run.' >&2
  exit 2
fi

agent=$(printf '%s' "$input" | jq -r '.agent_type // ""')
[ "$agent" = 'change-reviewer' ] || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Only plain words: letters, digits, spaces and `._/=:^~@+,-`. This leaves out
# every shell operator, quote, substitution and expansion; a tilde is allowed
# only inside a word (`HEAD~1`), where bash does not expand it. An argument never
# starts with `-`, so no flag beyond the listed ones reaches the command.
safe='^[A-Za-z0-9 ._/=:^~@+,-]*$'
arg='[^ -][^ ]*'
patterns=(
  "^fvm dart run tool/review_diff\\.dart( $arg| --)*\$"
  "^fvm dart run tool/check_spec\\.dart( --base $arg)?\$"
  "^fvm dart run tool/check_imports\\.dart\$"
  "^fvm flutter test( $arg)*\$"
  "^fvm (flutter|dart) analyze( $arg)*\$"
  "^fvm dart format --output=none( --set-exit-if-changed)?( $arg)+\$"
)

if [[ "$cmd" =~ $safe && ! "$cmd" =~ (^|[ =:])~ ]]; then
  for pattern in "${patterns[@]}"; do
    [[ "$cmd" =~ $pattern ]] && exit 0
  done
fi

cat >&2 <<EOF
Blocked: not a change-reviewer command: $cmd
Allowed, one command per call, from the repository root, without cd, quotes,
pipes, redirects or other flags:
  fvm dart run tool/review_diff.dart <args>
  fvm dart run tool/check_spec.dart [--base <ref>]
  fvm dart run tool/check_imports.dart
  fvm flutter test [<paths>]
  fvm flutter analyze [<paths>] | fvm dart analyze [<paths>]
  fvm dart format --output=none [--set-exit-if-changed] <paths>
EOF
exit 2
