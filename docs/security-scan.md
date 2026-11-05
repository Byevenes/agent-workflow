# Security scan

A repo under the clients root uses the client path. This repo, and any other repo you own, uses the personal path. The client map stays on the machine. This playbook does not name a client.

## Client path

The scan stays on the developer machine. Nothing on this path is committed. This change does not install a hook and does not add a tracked file to a client repo.

[SonarQube for IDE](https://docs.sonarsource.com/sonarqube-development-tools) is the editor extension. Install it in the editor on your machine. Do not commit a SonarQube project file or an IDE binding.

Run [gitleaks](https://github.com/gitleaks/gitleaks) on the machine, from the client repo root. The zStack Pre-push gate scans **only this branch against its base**, not the full history:

```sh
gitleaks git --log-opts="<base>..HEAD" --redact
```

Replace `<base>` with the merge base for the branch (for example `origin/main`, or the default branch the project KDB names). `gitleaks protect --staged --redact` covers uncommitted staged changes before a local commit.

A bare `gitleaks git --redact` walks the whole history. Client repos often carry known debt in old commits. That full-history result is not the pre-push criterion. The pre-push gate fails only when **new commits on this branch** introduce a secret. The client pipeline remains the source of truth for what blocks a merge.

On macOS, `brew install gitleaks` installs the binary. Do not commit a gitleaks config file or a gitleaks ignore file. The default rules are enough.

Never install a hook into a client repo. Do not set `core.hooksPath`. Do not add a husky directory, a githooks directory, or a pre-commit config.

Never commit security scanner config into a client repo.

Client quality thresholds (coverage, severity gates, quality profiles) live in the client pipeline and in that project's KDB. Do not invent a quality profile for the client inside this repo, and do not add a required field for it in `clients.toml`.

When a local file must stay untracked, add its name to `.git/info/exclude`. That file belongs to the clone. Do not add the line to `.gitignore`.

`scripts/setup-check.sh` already appends the scratch and atl artifact lines to each client repo's info/exclude. It does not install a hook. It does not write scanner config. It reports whether `gitleaks` is on PATH (`gitleaks: present` or a warn when missing) and does not install the binary. This change leaves that behavior as it is.

## Personal path

Personal repos may run the scan in CI. This repo is the example. Copy the workflow into another personal repo when you want the same scan. Never copy it into a client repo.

`.github/workflows/gitleaks.yml` runs on pull requests and on pushes to `main`. The job permission is `contents: read`. It checks out full history, downloads gitleaks 8.30.1, checks the sha256, and runs `gitleaks git . --redact`. It does not use a license token. It does not use `pull_request_target`.

## CodeQL

CodeQL is a poor fit for this repo. The tree is POSIX shell and markdown. CodeQL does not analyze shell. A workflow-only language pack would miss the scripts, and the CodeQL bundle is a heavy job for that narrow look. Secret scanning stays with gitleaks. Shell stays with shellcheck in `scripts/check.sh`.

A personal repo that is mostly a language CodeQL supports may add CodeQL there. A client repo may not.

## Future / optional

A developer may later run SonarQube Community in Docker on their own machine, outside every client repo. The compose file and any local quality profile live under personal tooling, never under a client worktree. Client quality profiles arrive only by export from the client Sonar instance or by SonarQube for IDE connected mode. Do not invent a client quality profile in git. Until that optional step exists, SonarQube for IDE plus the branch-vs-base gitleaks gate above is enough for the local path.

## Where each piece lives

| Piece | Where it lives |
| --- | --- |
| Editor extension and the gitleaks binary | Developer machine, outside the client repo |
| A local exclude | `.git/info/exclude` in that clone |
| Personal CI | This repo, `.github/workflows/gitleaks.yml` |
| Optional SonarQube Community (Docker) | Developer machine / personal tooling, never a client repo |
