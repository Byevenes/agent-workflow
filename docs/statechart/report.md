# ZStack

TLC reached 133 states and 158 steps. The chart draws 28 states and 30 arrows.
The chart does not draw 27 steps that stay in one chart state.

## EditNeedsZninjaOrReason breaks
The shortest path has 3 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. the agent codes inline without a reason: Code written, inline, no reason

## MediumUpIndependentReview breaks
The shortest path has 6 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. the agent codes inline and writes the reason: Code written, inline, reason recorded
4. the change is reviewed: Reviewed, inline, reason recorded, self-check only
5. pre-commit, CI and zretro pass: Checks green + retro, inline, reason recorded, self-check only
6. zpr opens the PR [personal repo]: PR open (zpr body), inline, reason recorded, self-check only

## OnlyBrayanMerges breaks
The shortest path has 7 steps:
0. Request received
1. zStack classifies the task: Classified (size printed)
2. zgrill / zspec / ztickets plan it: Planned (.scratch spec)
3. zNinja writes the code: Code written, by zNinja
4. the change is reviewed: Reviewed, by zNinja, zSensei
5. pre-commit, CI and zretro pass: Checks green + retro, by zNinja, zSensei
6. zpr opens the PR [personal repo]: PR open (zpr body), by zNinja, zSensei
7. the agent automerges [pure refactor]: Merged, by zNinja, zSensei, by the agent

## Rules that hold
NoEditBeforeClassify, BigNeedsApproval, ClientNeverPublishes, NoDeadlock
