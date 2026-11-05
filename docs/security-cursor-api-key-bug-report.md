# Draft bug report: API key visible in cursor-agent arguments

Status: draft. Not sent.

Send this through Cursor's bug channel when you choose to. Remove the status lines above before you send it. Read the whole draft again and confirm it contains no key value.

## Title

API key appears in `ps` arguments of `cursor-agent`

## Report

The Cursor CLI can expose a user API key in the process arguments of `cursor-agent`. A local `ps` listing shows the key. Any local user who can list processes can read it.

No key value is included. Do not ask for the raw value.

### Expected

Process arguments of `agent` and `cursor-agent`, including worker processes, never contain the API key or an auth token. The process should read `CURSOR_API_KEY` from the environment, or use the session from `agent login`, without copying that secret onto argv.

### What happened

A `ps` listing showed the key in the arguments of a `cursor-agent` worker. This draft does not include that listing, because the listing contained the secret.

### Docs that describe the current interface

The CLI authentication docs recommend browser login. For automation they recommend the `CURSOR_API_KEY` environment variable. They also document `--api-key`, which places the secret in argv. The parameters page lists that flag next to the environment variable. ACP docs also mention `--auth-token` and `CURSOR_AUTH_TOKEN`.

https://cursor.com/docs/cli/reference/authentication

https://cursor.com/docs/cli/reference/parameters

Please confirm whether a worker copies `CURSOR_API_KEY`, a login session, or only an explicit key flag onto its argv.

### Change that would remove the exposure

Do not place the secret in argv. If the flag must stay for compatibility, accept it and remove the value from the visible argument list before any worker starts. Keep reading the environment variable and the `agent login` session inside the process.

### Environment

The binary name observed was `cursor-agent`. The docs also call it `agent`. The host was macOS. This report has no key, no account email, and no log excerpt.
