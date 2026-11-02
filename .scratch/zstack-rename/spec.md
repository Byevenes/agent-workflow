# Spec: rename route-work to zStack and apply approved decisions

Status: ready-for-agent. Approved by Brayan on 2026-11-02 (run end to end, personal repo, merge allowed).

`route-work: large, full verifiable — rename across every copy of the router plus new checks; scripts/check.sh and sh -n prove alignment.`

## Outcome

The flow is called zStack. Roles: zIGL routes, zNinja implements, zSensei reviews. zHunter and zGuard are reserved names. `route-work` stays as an alias until 2026-12-01 so old rules, installs and `scripts/route-audit.sh` keep working.

## Decisions in scope

4/25 merge policy, 16 delivery template, 18 fresh-context subagents, 19 one zNinja per Large slice, 20 no-comments lint (personal repos), 22 zSensei reads the test diff, 23 optional statechart, 24 planning skills stay model-invocable, 26 Medium full-spec in one session, 27 where does the state live, 28 Sandcastle reference, 29 retro ends in a lint or test via `correct`, 30 automatic barriers first, 31 per-repo verification skill, 32 in-your-own-words before spec, 33 how do we measure success, 34 implicit state machines prompt.

## Where does the state live?

In the repo files. Installed copies on each machine are symlinks made by `scripts/link.sh`; nothing else holds state.

## How do we measure success?

`scripts/check.sh` green locally, in the hooks and in CI; `scripts/route-audit.sh` still counts old and new prefixes.

## Out

Plugin packaging (decision 21). Syncing installed copies on the Mac. Client repos. Decision 35 (dr eggbot).

## Acceptance

- Every copy (skill, rule, OpenCode agent, agents, README, AGENTS, docs) uses the zStack names and the same inline-trigger sentence.
- Client-repo rules stay: never `--force`, no commit, push, MR or PR without Brayan's order, stay in the worktree, everything needs his approval.
- No SDD, tech-lead or test-engineer reference in the zStack copies.
- `scripts/check.sh` enforces alignment, banned references, and the comment rule; hooks and CI run it.
