#!/usr/bin/env bash
# The CCA plugin's Stop hook: when the working tree has changes in a language the dependency check reads, remind the agent
# to run `check_dependencies` before it reports the work done. It ONLY reminds: it always exits 0 and never asks to block (our
# "never blocks" rule). Opt out with CCA_NUDGE=off. If it is ever made to block, it must keep exiting at once when the hook
# input says stop_hook_active (or the agent loops forever).
# The languages are generated (languages.txt, from the dependency check's own list): never edit them by hand.
set -u
input=$(cat 2>/dev/null || true)
[ "${CCA_NUDGE:-on}" = off ] && exit 0
case "$input" in *'"stop_hook_active": true'*|*'"stop_hook_active":true'*) exit 0 ;; esac
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
langs="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/hooks/languages.txt"
[ -r "$langs" ] || exit 0
changed=$( { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | sort -u)
[ -n "$changed" ] || exit 0
hits=0
while IFS= read -r ext; do
  [ -n "$ext" ] || continue
  if printf '%s\n' "$changed" | grep -qiE "\\${ext}\$"; then hits=1; break; fi
done < "$langs"
[ "$hits" = 1 ] || exit 0
printf '%s\n' '{"systemMessage": "CCA: this change touches code the dependency check reads. Run the check_dependencies tool on your diff before reporting the work done (set CCA_NUDGE=off to stop this reminder)."}'
exit 0
