---
description: Scan this repository with Canine Code Analyzer (/v1) and read the scores and open findings
allowed-tools: Bash("${CLAUDE_PLUGIN_ROOT}/scripts/cca-scan.sh")
---

Scan this repository with Canine Code Analyzer through its public API and report what it measured.

1. Run `"${CLAUDE_PLUGIN_ROOT}/scripts/cca-scan.sh"` with the Bash tool and a timeout of 10 minutes (600000 ms); a scan takes
   minutes. It reads the organisation's API key from `CCA_API_KEY` itself: never print the key, never put it on a command line.
   If the run is still going when the timeout ends, the script names the run: say so, and stop.
2. If the script fails (exit 1), tell me its message as it is and stop: it says what is missing (the key, the repository's
   connection, the plan's credit) and where to fix it. Do not try other endpoints.
3. Otherwise tell me, in this order and briefly:
   - which commit was measured, and whether it is the one my working tree is on (the API measures the default branch's latest
     pushed commit, never local changes);
   - the headline score, its band and the lens scores;
   - the open findings, grouped by dimension, most severe first, each with its file and line.
4. Change no code. If I then ask you to fix a finding, read the code at its file and line first.

$ARGUMENTS
