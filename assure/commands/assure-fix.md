---
description: Fix what Assure found in this repository, most important first
---
Use the **assure** MCP server to fix what Assure found in this repository.

1. Call `next_task`. It gives you the most important thing to fix, with every place it occurs.
2. Fix the real cause in the code, at every place. Never change code only to quiet the finding.
3. Call `resolve_finding` for each place you fixed, with a short note saying what you changed.
4. If a finding is wrong, call `dispute_finding` and say why, quoting the code.
5. Call `next_task` again. Stop only when it returns nothing.

Tell the user in plain words what you changed and why it matters for their app. Assure's next scan checks that each thing is gone.
