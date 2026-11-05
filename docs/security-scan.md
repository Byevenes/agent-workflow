# Security scan

A repo under the clients root uses the client path. This repo, and any other repo you own, uses the personal path. The client map stays on the machine. This playbook does not name a client.

## Client path

The scan stays on the developer machine. Nothing on this path is committed. This change does not install a hook and does not add a tracked file to a client repo.

[SonarQube for IDE](https://docs.sonarsource.com/sonarqube-development-tools) is the editor extension. Install it in the editor on your machine. Do not commit a SonarQube project file or an IDE binding.

Run [gitleaks](https://github.com/gitleaks/gitleaks) on the machine, from the client repo root.

```sh
gitleaks git --redact
```

On macOS, `brew install gitleaks` installs the binary. Do not commit a gitleaks config file or a gitleaks ignore file. The default rules are enough.

Never install a hook into a client repo. Do not set `core.hooksPath`. Do not add a husky directory, a githooks directory, or a pre-commit config.

Never commit security scanner config into a client repo.

When a local file must stay untracked, add its name to `.git/info/exclude`. That file belongs to the clone. Do not add the line to `.gitignore`.

`scripts/setup-check.sh` already appends the scratch and atl artifact lines to each client repo's info/exclude. It does not install a hook. It does not write scanner config. This change leaves that behavior as it is.

## Personal path

Personal repos may run the scan in CI. This repo is the example. Copy the workflow into another personal repo when you want the same scan. Never copy it into a client repo.

`.github/workflows/gitleaks.yml` runs on pull requests and on pushes to `main`. The job permission is `contents: read`. It checks out full history, downloads gitleaks 8.30.1, checks the sha256, and runs `gitleaks git . --redact`. It does not use a license token. It does not use `pull_request_target`.

## CodeQL

CodeQL is a poor fit for this repo. The tree is POSIX shell and markdown. CodeQL does not analyze shell. A workflow-only language pack would miss the scripts, and the CodeQL bundle is a heavy job for that narrow look. Secret scanning stays with gitleaks. Shell stays with shellcheck in `scripts/check.sh`.

A personal repo that is mostly a language CodeQL supports may add CodeQL there. A client repo may not.

## Where each piece lives

| Piece | Where it lives |
| --- | --- |
| Editor extension and the gitleaks binary | Developer machine, outside the client repo |
| A local exclude | `.git/info/exclude` in that clone |
| Personal CI | This repo, `.github/workflows/gitleaks.yml` |
