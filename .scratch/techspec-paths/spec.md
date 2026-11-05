# Spec: TechSpec paths from the repo root

Status: ready-for-agent. The acceptance text in the task is the confirmation of this restatement.

`zstack: Medium, full verifiable — the template, the checker, and the clean and dirty fixtures are all proven by scripts/check.sh.`

Matt's `grill-with-docs` and `to-spec` files are not installed on this machine (`~/.agents/skills/` is absent). This spec answers the wrapper questions directly. The task already fixed the outcome.

## Problem

TechSpecs cite files with a short name (`Bar.cs`) or with a path relative to the agent's working directory. A reviewer in another session cannot resolve the file. Absolute paths of the local machine are worse: they do not travel.

## Restatement

A TechSpec cites each file as a path from the repository root, for example `src/Foo/Bar.cs`. A bare filename is not enough when the file is not at that root. An absolute machine path is never written. A command fails when a citation does not exist from the root or is an absolute machine path.

## Where does the state live?

Nowhere new. A citation is text in the markdown file. The checker reads that file and the repository directory it is given. It does not write, cache, or remember a previous run.

## How do we measure success?

`scripts/check-techspec-paths.sh` exits 0 on the clean fixture and non-zero on each dirty fixture. `scripts/check.sh` runs those cases. That is the CI job `check`.

## Decisions

- A citation is an inline code span or a markdown link target, not a fenced sample and not a URL.
- The checker classifies each citation as absolute, escape (`..`), or relative. Only a relative citation is looked up, and only under the given root.
- A bare name such as `Bar.cs` is a relative citation. It passes only when that file is at the root.
- The template sentence that said to cite code as a class or method is removed. The checker plus one template rule replace it.
- `scripts/check.sh` runs the fixtures. It does not scan every markdown file in the repo.

## Acceptance

- `skills/to-techspec/SKILL.md` requires a repo-root path, with the example `src/Foo/Bar.cs`, and names `scripts/check-techspec-paths.sh`.
- `skills/zspec/SKILL.md` names the same rule and the same command.
- The command fails for a missing path, a bare name that is not at the root, an absolute machine path, and a path that escapes the root.
- The clean fixture passes, including a class name, a URL, a root file, a directory, a line suffix, and a fenced sample that is not a citation.
- No skill text tells the author to write an absolute machine path.

## Out

Scanning every markdown file on each commit. Searching the tree to "find" a short name. Enforcing the rest of the TechSpec neutrality rules (names, hosts, line-number policy) in this command.
