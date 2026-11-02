#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
fail=0
bad() { echo "FAIL $*"; fail=1; }

trigger='Run inline when the Task tool is absent, or its subagent list does not include zninja, or one launch attempt returned an error (quote it in the reason), or this session is a whole task that arrived with no parent and is running headless without subagents; if the Task tool exists and lists zninja, you must launch it.'
for f in skills/zstack/SKILL.md rules/zstack.mdc agents/opencode/zstack.md README.md AGENTS.md docs/software-factory.md docs/workflow.md; do
  grep -qF "$trigger" "$f" || bad "$f: inline-trigger sentence missing or drifted"
done

for f in skills/zstack/SKILL.md agents/opencode/zstack.md; do
  grep -q -- '--force' "$f" || bad "$f: client rule about --force missing"
done

if grep -rnE 'SDD|sdd-|tech-lead|test-engineer' skills/zstack rules agents; then bad "zstack copies reference SDD, tech-lead or test-engineer"; fi

if grep -rnE '"subagent_type": *"(implementer|code-reviewer)"|`(implementer|code-reviewer|coordinator)`' skills/zstack rules agents README.md AGENTS.md docs/software-factory.md docs/workflow.md; then bad "old role names in live copies"; fi

for f in scripts/*.sh .githooks/*; do
  sh -n "$f" || bad "$f: syntax"
  if awk 'NR>1 && /^[[:space:]]*#/ && !/https?:\/\/|SPDX|[Ll]icense/' "$f" | grep -q .; then bad "$f: comment without issue/RFC link or license"; fi
done

if command -v shellcheck >/dev/null 2>&1; then shellcheck -e SC2016 scripts/*.sh .githooks/* || bad shellcheck; else echo "skip shellcheck (not installed)"; fi

[ "$fail" -eq 0 ] && echo "check ok"
exit "$fail"
