# Open decisions

The issue text does not settle these. The code does not pick for Classify.

## Commit-order gate on Large (#47)

Classify still chooses whether a Large run requires `scripts/check-commit-order.sh`. This change leaves the gate unwired from `scripts/check.sh`.

1. Optional. Classify marks the gate required only when the branch will have several commits and the cost is acceptable.
2. Required on every Large run before the work is called done.
3. Required only when `base..HEAD` contains more than one commit.

## Out-of-scope bug gate (#44)

zNinja stops and asks. An approved fix is a `fix:` commit before the feature commit. The acceptance criterion is that protocol plus a review checklist. It does not choose an automatic reject.

1. Checklist only. zNinja stops. zSensei checks that the `fix:` commit is an ancestor of the feature commit and that they are not the same commit.
2. A gate that fails a feature commit whose paths sit outside a file list named by the ticket. The ticket has to name those files.
3. A gate that fails when one commit subject is both `fix:` and `feat:`. That misses a mixed diff with a single subject.

Shipped the checklist from the acceptance criteria. Did not add a reject script.
