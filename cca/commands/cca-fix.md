---
description: Fix what the scan found in this repository, most important first, verified by the next scan
---
Use the **cca** MCP server to work this repository's findings.
Your agent knows it as **cca**, or by the name you gave the server when you added it.

**The goal: every finding the scan reported is looked at and given the right ending: fixed, disputed or accepted.** `next_task`
serves one **cause** at a time (the problem a group of findings share), with every place it occurs. The server decides the order:
security findings first, then the rest by what fixing them is worth. That order decides what you work on first. It never decides
how much of the list you work, and it never decides WHAT you change.

**Fix the real cause, always.** Before you edit, describe the problem in words an engineer who has never seen the scanner would
recognise. If the only description is "it is flagged", the code may be fine: dispute or accept, don't change it to silence it.
Never change code only to quiet a finding.

Loop:
1. Call `next_task`. It gives you the next cause, fully briefed: what to do, every instance (file:line and fingerprint), the
   `causeKey` and a `progress` block. A packet carries at most 50 instances; when a cause has more, work them and call again.
2. Give the cause **one of three endings**:
   - **Fix it**: change the code at every instance, then `resolve_finding` each with a short note saying what you changed. The
     next scan checks it, so never claim a fix you didn't make.
   - **Dispute it**: `dispute_finding` if the finding is wrong (it isn't there) or is noise nobody should be shown. Quote the code
     at the cited line as `evidence`. Pass further instances of the same root cause as `siblingFingerprints`: one dispute, not many.
   - **Accept it**: `set_cause_disposition(dimension, cause, "Accepted", note)` if the finding is correct and you are deliberately
     not acting. Say in the note why it does not apply here. The owner confirms it on the findings page.
3. Call `next_task` again, every time. Stop only when it returns nothing.

Rules:
- **Count in items, as the app does.** `audit` has a `list` block: the items on the list the product's app shows, in total and per
  area, and every `progress` block carries `itemsOnList`. One item can be several findings (one package's licence parts, one function's
  two measures, one weakness two checks found at one place); a packet's `sameItem` names the other findings of an instance's item: fix
  it once and resolve each of them. When you report numbers to the person, use these, so they match what the app shows.
- **Only an empty `next_task` ends the loop.** Don't stop because the rest looks less important.
- **Stall guard:** if `next_task` hands you the same cause twice with nothing resolved or decided in between, stop and say so.
- **Posture tasks** (`kind: "posture"`) have no instances: the brief is the work. Close it with `set_cause_disposition` against
  `causeKey: "__posture__"`.
- An **advisory** finding (`advisory: true`) does not move the score and cannot be disputed: fix it, accept it, or use
  `flag_advisory` with a note if it looks wrong.
- Suppressing a finding **in the code** (an inline suppression, an ignore entry, a config exemption) is a human decision, never yours.
- If you run low on context before the list is done, write down the goal, the `progress` block and what you closed, so the next
  session carries on with the whole job.

When `next_task` returns nothing, tell me in plain words what you fixed and why it matters, what you disputed and why, and what you
accepted and why (as a list I can confirm on the findings page). If the repository allows it, call `request_rescan`; otherwise tell
me the next scan checks the fixes.

$ARGUMENTS
