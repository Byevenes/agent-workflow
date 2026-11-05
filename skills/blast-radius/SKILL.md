---
name: blast-radius
description: "List every in-module caller of a changed symbol, including private methods and indirect callers, and fail when the report misses one. Use with the upstream blast-radius skill before a shared fix."
---

# Blast radius callers

Read the upstream pstack `blast-radius` skill and do that job. This file is the caller gate that skill does not check. Upstream text stays upstream.

Before changing a shared symbol, write a call graph for its module and run `scripts/blast-radius-callers.sh` from this repository. The graph file is the only state. The script prints each in-module caller as a file and a symbol. It includes private methods and callers that reach the symbol only through another symbol. It stays inside the changed symbol's module. The changed symbol is not listed as its own caller.

The same script fails when an `--expect` report misses or adds a caller. `scripts/check.sh` runs that failure on a fixture. The check fails when the report misses one.

## Graph

Whitespace-separated, one fact per line. Tokens contain no spaces.

- `symbol`, id, `public` or `private`, module, file
- `edge`, caller id, callee id

A duplicate id, an edge that names an unknown id, or an unknown target is an error. Visibility is recorded so a private symbol stays in the walk. The walk does not drop private symbols.

## Command

`scripts/blast-radius-callers.sh <graph> <symbol> [--expect <report>]`

Exit 0 when the walk finishes and, with `--expect`, the report matches. Exit 1 when the symbol is unknown or the report does not match. Exit 2 when the arguments or the graph are wrong.

## Fixture

`docs/examples/blast-radius-fixtures/graph.txt` changes `Order.Save`, a private symbol in module `billing`. Direct callers are `Order.Validate` (private) and `Report.Nightly` (public). `Order.Place` and `Checkout.Run` reach it only through `Order.Validate`. `Other.Touch` is another module and is not listed. `docs/examples/blast-radius-fixtures/save-callers.txt` is the full list. `docs/examples/blast-radius-fixtures/public-only.txt` keeps the public direct caller and drops the private and indirect ones, and the check fails.
