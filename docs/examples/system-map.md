# System map

Written at the start of `to-analysis`, before the detailed analysis. The task text is: "Round the order total the same way on the half-up path." It names no branch.

## Observed

- Module `orders` owns the total. Source: `src/orders/total.ts`, function `roundTotal`.
- Boundary: `payments` charges an amount and does not recompute it. Source: `src/payments/charge.ts` takes `amount` and does not import `orders`.
- Dependency: `orders` calls `money.round`. Source: the import in `src/orders/total.ts` and `src/money/round.ts`.
- Branch to compare: `fix/round-half-away`. Reason: that branch already edits `src/money/round.ts`. Source: the repo branch list and that branch's history for this file.

## Unconfirmed

- Whether `invoices` copies the rounded total or computes its own. Source: the task text mentions invoices. No file under `src/invoices` was opened.

## Branches that do not apply

The same branch list has other names. None of them edit `orders` or `money.round`, so none of those apply. Do not reuse `fix/round-half-away` on another task; it is a name this map read, not a default.

## Walk

Stay on `orders`, the `money.round` dependency, and the one branch that edits it. Do not open `payments` to change how a charge is built, and do not propose a new shared pricing module.
