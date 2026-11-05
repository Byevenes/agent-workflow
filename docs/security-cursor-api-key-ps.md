# Keep a Cursor API key out of process arguments

`ps` can show a Cursor API key in the arguments of `cursor-agent`. Anyone who can list processes on that machine can read the key. This repository cannot change the Cursor binary. Use this note to see the impact, to keep our own shell clean, and to follow the checklist after a suspected exposure.

The public issue is [Byevenes/agent-workflow#54](https://github.com/Byevenes/agent-workflow/issues/54). The unsent report is `docs/security-cursor-api-key-bug-report.md`.

## Symptom

A process listing shows `cursor-agent` with the API key in its arguments. The key is then visible to other users who can run `ps`, to a shared CI runner, and to anyone who captures that listing in a log or a screenshot.

Cursor's CLI authentication page, read on 2026-11-05, recommends `agent login` for a person and the `CURSOR_API_KEY` environment variable for automation. The same page also documents the `--api-key` flag. That flag puts the value in argv. A worker that copies the value into its own arguments does the same thing when the parent was started from the environment. This repository did not re-run that worker with a live key.

https://cursor.com/docs/cli/reference/authentication

## Impact

A person who can read the process list can call the Cursor API as that user. Revoke the key after any exposure. Do not paste the value into git, chat, a ticket, or the bug report.

## What this repository does

`scripts/`, `hooks/`, and `.githooks/` do not pass `--api-key` or `--auth-token` to `agent` or `cursor-agent`. `scripts/setup-check.sh` only checks that `cursor-agent` is on `PATH`. `scripts/check.sh` fails if one of those flags appears under those directories. The failure names the flag and the file. It does not print the matching line, so a real value on that line stays out of the log.

## Mitigations

Prefer `agent login` for interactive use. Cursor stores that session locally.

For automation, put the key in the environment and start the CLI without a key flag.

```sh
export CURSOR_API_KEY
agent
```

Do not pass `--api-key` or `--auth-token`. The environment stays out of a default `ps` listing. A same-user observer can still read the environment on many systems. If `ps` still shows the key after login, or after the environment variable alone, the leak is in the product. Rotate the key and use the draft report when you are ready to send it.

## Checklist after a suspected exposure

1. Revoke the key in the Cursor dashboard under API Keys, and create a replacement. Do not copy the old value into this repo, a chat, or the report.
2. Write down who else could list processes on that machine. Include a shared host, a CI runner, a pair session, and a screen recording.
3. Stop launching `agent` or `cursor-agent` with a key flag. Use `agent login`, or export `CURSOR_API_KEY` and start `agent` with no key flag.
4. Check a fresh `ps` listing after the change. If the key is still in argv, treat that as the product bug and keep the replacement key rotated until Cursor changes the worker.
5. Send `docs/security-cursor-api-key-bug-report.md` only after you have confirmed it contains no key value. This repository does not send it.
