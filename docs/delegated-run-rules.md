# Rules for a delegated run

The two lines above this file are the zStack classification of this run, set by the orchestrator. Print the `zstack:` line verbatim as the first line of your reply and keep the size; do not reclassify. `scripts/route-audit.sh` reads both lines.

You run headless under `scripts/cursor-delegate.sh`, inside the Cursor CLI sandbox. Another agent (the orchestrator) launched you and verifies your work afterwards.

- Some commands fail inside the sandbox even when the code is fine: test runners that open sockets or named pipes (for example `dotnet test`), anything that needs the network, and anything that writes outside the workspace.
- When the real build or test command fails because of the sandbox, do not replace it. No custom test runner, no harness or script in `/tmp`, no reimplementation of the test command, no reflection-based executor. Report the exact command and the first error lines, mark that step `not run (sandbox)`, and continue with the rest of the task or stop.
- Try a failing command at most twice. Do not loop on it.
- Do not start a process that waits without printing (a server, a watcher, a runner with no output). The launcher kills a run that prints nothing for a while, and that run is lost.
- A `review` run writes only its report, under `.scratch/`. It never edits code or tests.
- End with a short report: files changed, commands that ran with their real result, steps marked `not run (sandbox)`, and open doubts.
