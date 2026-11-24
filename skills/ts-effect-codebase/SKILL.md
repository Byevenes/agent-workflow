---
name: ts-effect-codebase
description: "Start or harden a TypeScript/Effect repo (strict tsconfig, oxlint type-aware, Effect anti-slop, vitest, bun, ADRs, feature map), and give zsensei a verifiable review bar for those repos."
---

# TypeScript / Effect codebase

Use this in two cases:

1. **Start or harden** a TypeScript/Effect repository to this baseline.
2. **Review** such a repository: `zsensei` treats the checklist below as the bar. A miss is a finding.

This baseline is generic. Do not treat another repository as a required dependency. The versions below were measured from a personal Effect + Bun CLI; re-check package peers before pinning.

## Stack

Runtime and package manager: Bun, with `"type": "module"`.

Keep every Effect package on the same version. Measured set:

- `effect`, `@effect/platform-bun`, `@effect/vitest`: 4.1.2
- `typescript`: 7.0.2
- `oxlint` and `@oxlint/plugins`: 1.94.0
- `@cloudflare/oxlint-config`: 0.1.0
- `tsrs`: `7.1.0-beta.tsrs4` (the TypeScript-aligned release; some preset docs still show `0.25.0-ts7.1.0-beta`)
- `vitest`: 5.1.0
- `mutant-cafe`: 0.1.7
- `@types/bun` when the runtime is Bun

Scripts:

- `typecheck`: `tsc --noEmit` (do not replace this with another checker)
- `lint`: `oxlint --type-aware --deny-warnings src test`
- `test`: `bun --bun vitest run`
- `mutants` (advisory, not CI): `mutant-cafe --in-diff-range origin/main...HEAD --jobs 4 --advisory`

Oxlint must stay inside the Cloudflare preset peer range (`oxlint ^1.94.0`, `tsrs >=0.25.0-ts7.1.0-beta`).

## tsconfig

Set `strict` to true, plus:

- `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, `noFallthroughCasesInSwitch`
- `verbatimModuleSyntax`
- `module`: `Preserve`, `moduleResolution`: `bundler`
- `target` and `lib`: ES2022
- `allowImportingTsExtensions`, `noEmit`, `skipLibCheck`
- `types`: `bun` when the runtime is Bun

## Lint

Put the oxlint config at the repo root and extend `@cloudflare/oxlint-config`.

Copy the Effect rules from `dmmulroy/anti-slop` (MIT) into the repo. They are not an npm dependency. Record the upstream commit in that folder's README, and load them as an oxlint jsPlugin.

Turn these on as errors:

- `anti-slop-effect/no-manual-effect-error-tag`
- `anti-slop-effect/no-service-constructor-imports`
- `anti-slop-effect/prefer-effect-match`

Turn these on once tagged values use `Data.taggedEnum`. Do not leave them off as a habit:

- `anti-slop-effect/no-manual-tag-comparison`
- `anti-slop-effect/no-manual-tagged-construction`

Lint fails the build (`--deny-warnings`).

## Effect

- Domain errors are `Data.TaggedError`, with a useful `message` and a `fix` when the user can act on it.
- Do not import a project-local `make<Capability>` service constructor into runtime code. Import the owning Layer, yield the service, and let requirements reach the composition root.
- In catch handlers, use `Effect.catchTag` / `Effect.catchTags` (or `catchReason` / `catchReasons`), not a manual `_tag` branch.
- Branch tagged values with `Match.tag` / `Match.tags` / the tagged-enum `$match` helper, not `switch` or `===` on `_tag`, and not a chained literal ternary.
- Construct tagged values with their Schema `.make`, class constructor, or `Data.taggedEnum` variant, not a literal `_tag` object.

## Tests and mutants

- Vitest. Test files follow the repo's layout; a clean default is `test/**/*.test.ts`.
- Raise `testTimeout` only when a test spawns a real process.
- Keep integration tests that spawn the app in the suite.
- `mutant-cafe` is advisory and stays out of CI. Commit first, because it diffs `HEAD`. It needs Node 24 and runs Vitest under Node, which is slower than `bun run test`. It exits 0 even when mutants are missed; read the missed-mutants file. For a whole module: `bunx mutant-cafe --file <path> --jobs 4`.

## Docs

- Numbered ADRs: title, status, context, the decision, and what was discarded and why.
- A feature map of user-facing commands or features. Each row names the behavior and the test or check that verifies it. A test reads the command tree (or equivalent) and fails when a row is missing, extra, or names a file that is not there. A new command gets a row before it ships.

## Harden an existing repo

Do not rewrite the repo. Add the missing pieces in this order, and keep the suite green after each step:

1. The strict tsconfig flags above.
2. Oxlint type-aware, the Cloudflare preset, and `--deny-warnings`.
3. The Effect anti-slop plugin, with the three error rules on first.
4. Align Effect package versions. New errors use `Data.TaggedError`; then migrate the old ones.
5. Vitest, plus the feature-map test when the project has a user-facing surface.
6. The advisory `mutant-cafe` script.
7. An ADR for any decision this hardening closes.

If the repo is not already on Effect, stop and say so. Do not force Effect onto another stack unless the user asked to migrate.

## zsensei checklist

On a TypeScript/Effect repo, mark each item pass, fail, or n/a, with evidence:

1. `tsc --noEmit` and `oxlint --type-aware --deny-warnings` are scripts, and both are green on this diff.
2. tsconfig has `strict` and the flags in the tsconfig section.
3. Lint extends the Cloudflare preset, is type-aware, and loads the Effect anti-slop rules. The three error rules are on. If the two tagged-enum rules are off, say why and whether tagged values have moved to `Data.taggedEnum`.
4. Effect packages share one version. New errors use `Data.TaggedError`.
5. No new runtime import of a `make<Capability>` constructor, no new manual `_tag` catch branch, and no new chained literal ternary that `prefer-effect-match` would catch.
6. New user-facing behavior has a test that would fail without the change, and a feature-map row if the map exists.
7. `mutant-cafe` is available as an advisory script. If it is, run it on the diff (`--advisory`) and report missed mutants. Advisory misses alone do not fail the review. Missing tests for new behavior do.
8. A closed design decision has an ADR, or an explicit reason why it does not.

A fail is a finding. Agreeing with the repo's README, or with the code, is not enough to drop one.
