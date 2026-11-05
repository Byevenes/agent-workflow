# Security scan paths

## Problem Statement

Client repos and personal repos need different secret and quality scans. A client remote must never receive scanner config, a scanner workflow, or a hook installed by this change. A personal repo, including this one, can run a scan in CI. Today nothing written down says which path is which, and this repo's CI does not run a secret scan.

## Solution

One playbook states the two paths. The client path is instructions for the developer machine: SonarQube for IDE in the editor, and gitleaks run locally. Nothing from that path is committed, and no hook is installed in the client repo. Local excludes, when a file must stay untracked, go in `.git/info/exclude`. The personal path documents CI. This repo gains a gitleaks workflow under GitHub Actions. CodeQL is not added here, because this tree is shell and markdown and CodeQL does not analyze shell.

## User Stories

1. As a developer on a client repo, I want the scan to stay on my machine, so that the client remote never stores scanner config.
2. As a developer on a client repo, I want SonarQube for IDE installed in the editor, so that I get findings without a project file in the repo.
3. As a developer on a client repo, I want to run gitleaks locally with secrets redacted in the output, so that a finding does not land in a scrollback I might paste.
4. As a developer on a client repo, I want a written ban on installing hooks into that repo, so that an agent does not set `core.hooksPath` or add a hook directory.
5. As a developer on a client repo, I want a written ban on committing scanner config, so that a SonarQube project file, a SonarQube for IDE binding, a gitleaks config file, and a gitleaks ignore file stay out of the remote.
6. As a developer on a client repo, I want local excludes in `.git/info/exclude`, so that a personal report or ignore file is not a `.gitignore` change.
7. As a developer on a client repo, I want `scripts/setup-check.sh` to keep doing only what it already does to client clones, so that this change does not write new exclude lines or hooks into those clones.
8. As a developer on a personal repo, I want the playbook to say CI is allowed, so that I do not copy the client ban onto a repo I own.
9. As a maintainer of this repo, I want gitleaks in GitHub Actions on pull requests and on pushes to `main`, so that a secret in history fails the check.
10. As a maintainer of this repo, I want the gitleaks job to read contents only, so that the workflow cannot push or comment.
11. As a maintainer of this repo, I want the downloaded gitleaks binary checked against a pinned sha256, so that the job does not run an unchecked archive.
12. As a maintainer of this repo, I want findings redacted in the log, so that a leak is not printed in full.
13. As a maintainer of this repo, I want no license token and no `pull_request_target`, so that the scan does not need a secret and does not run untrusted workflow code with the base repo's token.
14. As a maintainer of this repo, I want CodeQL left out, with the reason written in the playbook, so that a later reader does not add a heavy job that cannot see the shell.
15. As someone running `scripts/setup-check.sh`, I want a pointer to the playbook in the help text and in `docs/scripts.md`, so that the two paths are findable from the setup report.
16. As a reviewer, I want `scripts/check.sh` to fail when the playbook sentences or the workflow pins disappear, so that the contract is the same barrier as the rest of this repo.
17. As a reviewer, I want the public diff to contain no client names, people, or machine paths from the ban list, so that the public repo stays public-safe.
18. As a maintainer of another personal repo that is mostly a language CodeQL supports, I want the playbook to say CodeQL can live there and still must not be copied into a client repo.

## Implementation Decisions

- Two paths, chosen by where the repo lives. A repo under the clients root uses the client path. This repo, and any other repo the developer owns, uses the personal path. The client map stays local and untracked. The playbook does not name clients.
- State. There is no application state. The playbook and the workflow are files in this personal repo. A client exclude line lives only in that clone's `.git/info/exclude`. Editor extensions and the gitleaks binary live on the developer machine. CI logs live on GitHub.
- Client path does not change client repos. No new tracked file, no hook install, no edit to a client gitignore, and no new line written by `scripts/setup-check.sh` into client info/exclude. The existing scratch and atl artifact lines stay as they are.
- SonarQube for IDE is the editor product (the successor name of SonarLint). Connected mode and a SonarQube server are out of this change. The instruction is to install the extension on the machine and not to commit a binding.
- Local gitleaks is `gitleaks git --redact` from the client repo root, using the default rules. No committed config. Homebrew is the macOS install hint. A config file, if someone truly needs one, stays outside the repo or is named in `.git/info/exclude` and is never added.
- Personal CI for this repo is one workflow. Triggers match the existing check workflow's push to `main` and `pull_request`, without an `edited` type. Runner is `ubuntu-24.04`. Checkout is `actions/checkout` at the same major as `.github/workflows/check.yml`, with full history.
- gitleaks 8.30.1, linux x64 archive, sha256 `551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb`. The check style matches the pinned download in `.github/workflows/tla.yml`. Command is `gitleaks git . --redact --no-banner --exit-code 1`. Permission is `contents: read`. No `GITHUB_TOKEN`, no license variable, no third-party scanner action.
- CodeQL stays out. Record that in the playbook. Supported-language personal repos may add it later. Client repos may not.
- Pointer. `scripts/setup-check.sh --help` and `-h` print a usage line and the playbook path, then exit 0 before any other check. A normal run also prints that same info line. `docs/scripts.md` points at the playbook. `GLOSSARY.md` gains a Security scan entry.
- The automatic seam is `scripts/check.sh`, the same grep style as the other contracts. It locks the client bans, the `info/exclude` instruction, the CodeQL reason, the help pointer, and the workflow pin, permission, redact flag, and full history.

## Testing Decisions

- A good test here is a sentence a reader can observe in the playbook or the workflow. `scripts/check.sh` is the seam. It fails when those sentences or flags disappear. It does not execute gitleaks or SonarQube for IDE.
- Prior art is the existing grep contracts in `scripts/check.sh`.
- One extra invocation: `scripts/setup-check.sh --help` must mention the playbook and exit 0. That command must not scan client repos.
- What this seam misses, and how to check it by hand: open a pull request and confirm the gitleaks job is green; on a machine with the editor extension, confirm SonarQube for IDE is installed outside any client repo.

## Out of Scope

- Installing hooks, scanner config, or workflows into any client repo.
- Editing the user Cursor directory, the user config directory, or another worktree.
- A SonarQube server, connected mode, or a quality gate.
- CodeQL in this repo.
- A committed gitleaks config file or baseline. Defaults are the rules.
- Changing `scripts/setup-check.sh` so that it writes scanner excludes into client clones.

## Further Notes

- Measure. `sh scripts/check.sh` exits 0, and a ban search for client names, people, and machine paths returns no hits. The pull request is open against `main`.
- Security. Least privilege on the job token. Redact findings. Pin the binary with a checksum. Do not pass secrets into the workflow. Do not use `pull_request_target`. Do not log a token. Client scanner files never become tracked files.
- The written acceptance in the task is the approval to implement this run, including the pull request.
