# Delegated Cursor CLI runs

An orchestrator (another agent, or Brayan from a shell) hands a closed prompt to Cursor CLI and verifies the result itself. Launch it with `scripts/cursor-delegate.sh`, never with a bare `agent -p`.

## Why the sandbox flag

`~/.cursor/cli-config.json` uses `"approvalMode": "allowlist"` with a short allowlist (for example only `Shell(ls)`). In `--print` mode nobody answers the approval prompt, so every other command is rejected and the run writes code it cannot build or test. `--sandbox enabled` lets the agent run commands inside the macOS sandbox without widening the allowlist. `--auto-review` is the other option: a server classifier runs safe calls and rejects the rest. The launcher uses the sandbox by default and never uses `--force`.

## What does not work inside the sandbox

Some toolchains fail inside the sandbox even when the code is fine. Seen so far: `dotnet test`. Expect the same from anything that needs the network, local sockets or named pipes, or writes outside the workspace.

The rule for the delegated agent is in `docs/delegated-run-rules.md`, which the launcher puts at the top of every prompt: report the failing command, mark the step `not run (sandbox)`, and never build a substitute runner. A run that ignored this wrote its own test runner under `/tmp`, which hung with no output for about 45 minutes.

The orchestrator then runs, outside the sandbox and in the same worktree, every build or test step the report marks `not run (sandbox)`, and reports those results as its own evidence.

## Watchdog

The launcher asks for `stream-json`, so a live run keeps writing events. When the output file stops growing for `--idle` seconds (default 900), the launcher kills the whole process group, writes `exit=killed(idle Ns)` to `<out>.meta`, and exits 124. `--max` adds a hard wall-clock limit. After a kill, read the last events in `<out>` to see the stuck step, and run that step outside the sandbox.

## Proposal, not applied: `cli-config.json`

This repo does not edit `~/.cursor/cli-config.json`. Two options for Brayan:

1. Keep the allowlist and rely on the launcher flag (current state).
2. Set `"sandbox": { "mode": "enabled" }` in the config so interactive and headless runs behave the same. This changes every Cursor CLI session on the machine, so it is Brayan's call.
