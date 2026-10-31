#!/usr/bin/env bash
# The cca plugin's scan: start a scan of the repository this working tree belongs to through CCA's public API (/v1) with the
# organisation's API key, wait for its run, and print the result for the agent to read.
#
#   CCA_API_KEY            the organisation's API key (cca_...), from its API keys page; scopes account:read, scans:write,
#                          runs:read, results:read. Read from the environment only; it goes into the Authorization header and
#                          nowhere else (never onto a command line, never into the output).
#   CCA_API_URL            the API's address (default https://api.canine.dev).
#   CCA_SCAN_WAIT_SECONDS  how long to wait for the run (default 1800); CCA_SCAN_POLL_SECONDS between asks (default 10).
#   CCA_FINDINGS_LIMIT     how many open findings to read (default 50).
#
# /v1 scans the latest pushed commit of the repository's default branch, never local changes; the output says which commit
# was measured and whether it is the one the working tree is on.
set -u
api="${CCA_API_URL:-https://api.canine.dev}"; api="${api%/}"
wait_s="${CCA_SCAN_WAIT_SECONDS:-1800}"; poll_s="${CCA_SCAN_POLL_SECONDS:-10}"; limit="${CCA_FINDINGS_LIMIT:-50}"

say() { printf '%s\n' "$*"; }
fail() { say "cca-scan: $*"; exit 1; }

[ -n "${CCA_API_KEY:-}" ] || fail "no API key. Set CCA_API_KEY to a key from your organisation's API keys page (scopes account:read, scans:write, runs:read, results:read)."
command -v curl >/dev/null 2>&1 || fail "curl is needed."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "this is not a git repository."
remote=$(git remote get-url origin 2>/dev/null) || fail "this repository has no origin remote, so it cannot be matched to a connected repository."
# owner/name from any remote form: git@host:owner/name.git, https://host/owner/name(.git), ssh://git@host/owner/name.git
full=$(printf '%s' "$remote" | sed -E 's#/+$##; s#\.git$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#')

body=""; code=""
# call METHOD PATH: sets $code and $body. The key reaches curl on its stdin (a config line), never in its arguments.
call() {
  local out
  out=$(printf 'header = "Authorization: Bearer %s"\n' "$CCA_API_KEY" \
    | curl -sS -K - -X "$1" -H 'Accept: application/json' -w '\n%{http_code}' "$api$2" 2>&1) || { code=000; body="$out"; return; }
  code=${out##*$'\n'}; body=${out%$'\n'*}
}
# field NAME: the first value of "NAME" in $1 (compact JSON as /v1 writes it); empty for null.
field() { printf '%s' "$1" | grep -o "\"$2\":\(\"[^\"]*\"\|[^,}]*\)" | head -1 | sed -E "s/^\"$2\"://; s/^\"//; s/\"\$//; s/^null\$//"; }
refused() { # a non-2xx answer, in words
  case "$code" in
    000) say "cca-scan: $api could not be reached: $body" ;;
    401) say "cca-scan: 401, the API key was refused (unknown or revoked). Issue a new one on the API keys page." ;;
    403) say "cca-scan: 403, the key lacks a scope this needs: $(field "$body" detail)" ;;
    429) say "cca-scan: 429, the plan's rate was reached: $(field "$body" detail)" ;;
    *)   say "cca-scan: $1 answered $code: $(field "$body" detail)${body:+ ($body)}" ;;
  esac
  exit 1
}

call GET /v1/repositories
[ "$code" = 200 ] || refused "the repository list"
match=$(printf '%s' "$body" | tr -d '\n' | sed 's/},{/}\n{/g' | grep -iF "\"fullName\":\"$full\"" | head -1)
if [ -z "$match" ]; then
  say "cca-scan: $full is not among this key's organisation's repositories. Connect it first. The key reaches:"
  printf '%s' "$body" | grep -o '"fullName":"[^"]*"' | sed 's/"fullName":"/  /; s/"$//'
  exit 1
fi
repo=$(field "$match" id)
head=$(git rev-parse HEAD 2>/dev/null || true)

say "Scanning $(field "$match" fullName) (default branch $(field "$match" defaultBranch)) through $api/v1."
call POST "/v1/repositories/$repo/scans"
[ "$code" = 202 ] || refused "starting the scan"
scan=$(field "$body" scanId)
[ "$(field "$body" alreadyQueued)" = true ] && say "A scan of this repository was already waiting; following that one."
say "Scan $scan queued."

deadline=$(( $(date +%s) + wait_s ))
run=""
while :; do
  call GET "/v1/scans/$scan"
  [ "$code" = 200 ] || refused "the scan's status"
  run=$(field "$body" runId)
  [ -n "$run" ] && break
  case "$(field "$body" status)" in failed|cancelled|canceled)
    fail "the scan did not start: $(field "$body" status), $(field "$body" reason)" ;; esac
  [ "$(date +%s)" -lt "$deadline" ] || fail "the scan $scan is still waiting after ${wait_s}s. Its status: $api/v1/scans/$scan"
  sleep "$poll_s"
done
say "Run $run started."

status=""
while :; do
  call GET "/v1/runs/$run"
  [ "$code" = 200 ] || refused "the run's status"
  status=$(field "$body" status)
  case "$status" in completed|degraded|failed|cancelled|canceled) break ;; esac
  [ "$(date +%s)" -lt "$deadline" ] || fail "the run $run is still $status after ${wait_s}s. Read it later at $api/v1/runs/$run"
  sleep "$poll_s"
done
commit=$(field "$body" commit)
loc=$(field "$body" measuredLoc)
say "Run $run: $status, commit ${commit:-unknown}${loc:+, $loc lines measured}."
case "$status" in failed|cancelled|canceled) fail "the run did not finish: ${status}, $(field "$body" reason)" ;; esac
if [ -n "$commit" ] && [ "$commit" = "$head" ]; then
  say "This is the commit your working tree is on$( [ -n "$(git status --porcelain 2>/dev/null)" ] && printf ' (your uncommitted changes were not measured)')."
else
  say "This is the default branch's latest pushed commit, not your working tree (HEAD ${head:-unknown}): push your work to the default branch to have it measured."
fi

say ""
say "== Scores (GET /v1/repositories/$repo/scores) =="
call GET "/v1/repositories/$repo/scores"
case "$code" in 200) say "$body" ;; 402) say "This run is locked: $(field "$body" detail)" ;; *) refused "the scores" ;; esac
say ""
say "== Open findings, first $limit (GET /v1/repositories/$repo/findings?state=open&limit=$limit) =="
call GET "/v1/repositories/$repo/findings?state=open&limit=$limit"
case "$code" in 200) ;; 402) say "This run is locked: $(field "$body" detail)"; exit 0 ;; *) refused "the findings" ;; esac
results=$(field "$body" runId)
[ -n "$results" ] && [ "$results" != "$run" ] && say "These scores and findings are the latest run with results ($results), not the run just made ($run)."
say "$body"
exit 0
