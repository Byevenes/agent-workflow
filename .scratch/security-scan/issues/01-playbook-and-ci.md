# 01: Security scan playbook and personal gitleaks CI

**What to build:** A developer can read one playbook and know that a client repo is scanned only on the developer machine, and that this personal repo scans git history with gitleaks in CI. The setup report points at that playbook. The repo check fails if the playbook's client bans or the workflow pin disappear.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] The playbook states the client path (SonarQube for IDE and local gitleaks, no hook, no committed scanner config, `.git/info/exclude` for a local exclude) and the personal path (gitleaks in GitHub Actions for this repo).
- [x] The playbook says CodeQL is a poor fit here and is not added.
- [x] This repo has a gitleaks workflow with `contents: read`, a pinned checksum, redacted output, and full git history. It does not use `pull_request_target` or a license token.
- [x] `scripts/setup-check.sh` help text and `docs/scripts.md` point at the playbook. A normal setup-check run prints the same pointer. The script does not write new lines into client repos.
- [x] `scripts/check.sh` locks those observable sentences and flags.
- [x] No client repo is modified.
