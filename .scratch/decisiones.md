# Open decisions

The issue text does not settle these. The code does not pick for Classify.

## Commit-order gate on Large (#47)

Classify still chooses whether a Large run requires `scripts/check-commit-order.sh`. This change leaves the gate unwired from `scripts/check.sh`.

1. Optional. Classify marks the gate required only when the branch will have several commits and the cost is acceptable.
2. Required on every Large run before the work is called done.
3. Required only when `base..HEAD` contains more than one commit.
