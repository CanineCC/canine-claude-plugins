# Canine plugins for Claude Code

One marketplace (`canine`), one plugin per product that has a coding agent on the other end.

```
claude plugin marketplace add CanineCC/canine-claude-plugins
claude plugin install assert@canine     # or cca@canine
```

(Inside a session: `/plugin marketplace add CanineCC/canine-claude-plugins`, then `/plugin install assert@canine`.)

## Assert

- **Key:** the MCP server reads your repository's agent key from `ASSERT_AGENT_KEY` (agent keys are per repository; set it per
  repository, for example with direnv). The key is never written into a file of the plugin. The server is
  `https://app.assert.canine.dev/mcp` unless `ASSERT_MCP_URL` says otherwise.
- **Command:** `/assert:assert-fix` works the Assert audit (the same file the setup page's one-liner downloads).
- **Reminder:** when a change touches C#, Java, Kotlin or Scala, a Stop hook reminds the agent to run `check_dependencies` before
  reporting the work done. It never blocks. Turn it off with `ASSERT_NUDGE=off`.
- **Permissions:** allow `mcp__plugin_assert_assert__*` so every tool call is not asked for one by one.

## CCA

- **Key:** your organisation's API key (its API keys page) in `CCA_API_KEY`, with the scopes `account:read`, `scans:write`,
  `runs:read` and `results:read`. The address is `https://api.canine.dev` unless `CCA_API_URL` says otherwise.
- **Command:** `/cca:cca-scan` starts a scan of the repository your working tree belongs to (matched by its `origin` remote),
  waits for the run and reads the scores and open findings into the session. The API measures the default branch's latest
  pushed commit, never local changes; the command says which commit it measured.
- **MCP server `cca`** (`/mcp/cca`): the API as tools (list_repositories, start_scan, get_scan, get_scores, get_trend,
  list_findings, the finding lifecycle), through the same door as `/v1`: each tool needs its operation's scope. The address is
  `https://app.cca.canine.dev/mcp/cca` unless `CCA_MCP_URL` says otherwise. Allow `mcp__plugin_cca_cca__*`.
- The command pre-approves only its own script.

## Assure

- **Key:** the key from Assure's "Connect your AI tool" page (one per repository) in `ASSURE_AGENT_KEY`.
- **MCP server `assure`** (`/mcp/assure`): the repository's findings, most important first, to fix in its code: next_task,
  get_task, list_findings, get_finding, the claim, resolve and dispute of a finding, and set_cause_disposition. Nothing starts a
  scan; Assure scans on its own cadence. Allow `mcp__plugin_assure_assure__*`.

## Assay

- **Key:** an organisation API key with the scope `results:read`, from Assay's "Your AI assistant" page, in `ASSAY_API_KEY`.
- **MCP server `assay`** (`/mcp/assay`): READ-ONLY. list_codebases, get_codebase, get_report (the decision report's text and
  verdict) and explain_dimension (what a dimension means for a deal and who should care). It changes no code and orders nothing.
  Allow `mcp__plugin_assay_assay__*`.

