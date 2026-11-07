# ZStack

TLC reached 314 states and 452 steps. The chart draws 62 states and 65 arrows.
The chart does not draw 112 steps that stay in one chart state.

## NoEditBeforeClassify breaks
The shortest path has 1 step:
0. Request received
1. the agent edits before classifying: Edited before classifying

## BigNeedsApproval breaks
The shortest path has 2 steps:
0. Request received
1. the agent edits before classifying: Edited before classifying
2. zStack classifies the task: Classified (size printed)

## MediumUpByZninja breaks
The shortest path has 3 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. the agent codes inline above Small: Code written, inline, reason recorded

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
4. the change is reviewed: Reviewed, by zNinja, light review
5. pre-commit, CI and zretro pass: Checks green + retro, by zNinja, light review
6. the agent posts the client PR: PR open (zpr body), by zNinja, light review

## LargeCriticalIndependentReview breaks
The shortest path has 6 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. the agent codes before Brayan approves [Large or Critical]: Code written, by zNinja
4. the agent skips zSensei [Large or Critical]: Reviewed, by zNinja, self-check only
5. pre-commit, CI and zretro pass: Checks green + retro, by zNinja, self-check only
6. zpr opens the PR [personal repo]: PR open (zpr body), by zNinja, self-check only

## OnlyBrayanMerges breaks
The shortest path has 7 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. zNinja writes the code: Code written, by zNinja
4. the change is reviewed: Reviewed, by zNinja, light review
5. pre-commit, CI and zretro pass: Checks green + retro, by zNinja, light review
6. zpr opens the PR [personal repo]: PR open (zpr body), by zNinja, light review
7. the agent merges: Merged, by zNinja, light review, by the agent

## Rules that hold
NoDeadlock
