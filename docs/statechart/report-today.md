# ZStack

TLC reached 347 states and 500 steps. The chart draws 62 states and 65 arrows.
The chart does not draw 127 steps that stay in one chart state.

## NoEditBeforeClassify breaks
The shortest path has 1 step:
0. Request received
1. the agent edits before classifying: Edited before classifying

## BigNeedsApproval breaks
The shortest path has 2 steps:
0. Request received
1. the agent edits before classifying: Edited before classifying
2. zStack classifies the task: Classified (size printed)

## EditNeedsZninjaOrReason breaks
The shortest path has 3 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. the agent codes inline without a reason: Code written, inline, no reason

## ClientNeverPublishes breaks
The shortest path has 6 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. zNinja writes the code: Code written, by zNinja
4. the change is reviewed: Reviewed, by zNinja, diff read
5. pre-commit, CI and zretro pass: Checks green + retro, by zNinja, diff read
6. the agent posts the client PR: PR open (zpr body), by zNinja, diff read

## MediumUpIndependentReview breaks
The shortest path has 6 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. zNinja writes the code: Code written, by zNinja
4. the agent skips zSensei [Medium and up]: Reviewed, by zNinja, self-check only
5. pre-commit, CI and zretro pass: Checks green + retro, by zNinja, self-check only
6. zpr opens the PR [personal repo]: PR open (zpr body), by zNinja, self-check only

## OnlyBrayanMerges breaks
The shortest path has 7 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. zNinja writes the code: Code written, by zNinja
4. the change is reviewed: Reviewed, by zNinja, diff read
5. pre-commit, CI and zretro pass: Checks green + retro, by zNinja, diff read
6. zpr opens the PR [personal repo]: PR open (zpr body), by zNinja, diff read
7. the agent merges: Merged, by zNinja, diff read, by the agent

## Rules that hold
NoDeadlock
