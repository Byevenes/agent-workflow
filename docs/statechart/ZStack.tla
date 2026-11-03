---- MODULE ZStack ----
\* Model of the zStack workflow as written in skills/zstack/SKILL.md (agent-workflow @ d447961),
\* plus one step the skill forbids but nothing enforces (EditInlineNoReason), which route-audit.sh
\* observed in 13 of 19 editing sessions.
EXTENDS TLC

Sizes == {"small", "medium", "large", "critical"}
Repos == {"personal", "client"}

VARIABLES phase, size, repo, impl, reviewer, approved, edited, published, mergedBy
vars == <<phase, size, repo, impl, reviewer, approved, edited, published, mergedBy>>

Init ==
  /\ phase = "requested" /\ size = "none" /\ repo \in Repos
  /\ impl = "none" /\ reviewer = "none" /\ approved = FALSE
  /\ edited = FALSE /\ published = FALSE /\ mergedBy = "none"

\* §1 Classify: print "zstack: <size> ..." before anything else.
Classify == phase = "requested" /\ \E s \in Sizes : size' = s
  /\ phase' = "classified" /\ UNCHANGED <<repo, impl, reviewer, approved, edited, published, mergedBy>>

\* §2 Plan: zgrill / zspec / ztickets, written to .scratch/.
Plan == phase = "classified" /\ phase' = "planned"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published, mergedBy>>

\* §2 Large/Critical: stop for Brayan's approval before any code.
BrayanApprovesPlan == phase = "planned" /\ size \in {"large", "critical"}
  /\ approved' = TRUE /\ phase' = "approved"
  /\ UNCHANGED <<size, repo, impl, reviewer, edited, published, mergedBy>>

ReadyToCode == (phase = "planned" /\ size \in {"small", "medium"}) \/ phase = "approved"

\* §3 zninja subagent writes the code.
LaunchZninja == ReadyToCode /\ impl' = "zninja" /\ edited' = TRUE /\ phase' = "implemented"
  /\ UNCHANGED <<size, repo, reviewer, approved, published, mergedBy>>

\* §3 inline trigger: no Task tool / zninja missing / launch error; writes `inline: <reason>`.
EditInlineWithReason == ReadyToCode /\ impl' = "inline_reason" /\ edited' = TRUE /\ phase' = "implemented"
  /\ UNCHANGED <<size, repo, reviewer, approved, published, mergedBy>>

\* Not allowed by the skill, but no hook/CI blocks it (route-audit: 13/19 sessions).
EditInlineNoReason == ReadyToCode /\ impl' = "inline_noreason" /\ edited' = TRUE /\ phase' = "implemented"
  /\ UNCHANGED <<size, repo, reviewer, approved, published, mergedBy>>

\* §4 Check. Subagent path: small = read diff, medium+ = zsensei.
\* Inline path: "Do not launch a reviewer subagent on that path. Set reviewers: inline self-check."
Review == phase = "implemented" /\ phase' = "reviewed"
  /\ reviewer' = (IF impl = "zninja"
                   THEN (IF size = "small" THEN "diff_read" ELSE "zsensei")
                   ELSE "self_check")
  /\ UNCHANGED <<size, repo, impl, approved, edited, published, mergedBy>>

\* pre-commit + CI `check` green, then zretro.
ChecksAndRetro == phase = "reviewed" /\ phase' = "retro_done"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published, mergedBy>>

\* §5 Personal: open the PR with a zpr body.
OpenPR == phase = "retro_done" /\ repo = "personal" /\ published' = TRUE /\ phase' = "pr_open"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, mergedBy>>

\* §5 Client: zpr writes .scratch/pr-body.md only; never posts.
DraftForBrayan == phase = "retro_done" /\ repo = "client" /\ phase' = "draft_ready"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published, mergedBy>>

BrayanMerges == phase = "pr_open" /\ mergedBy' = "brayan" /\ phase' = "merged"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published>>

\* §5 "automerge only in personal repos and only for a pure, reversible refactor with green
\* checks and a clean zSensei pass". Modeled loosely: any personal PR the agent reviewed cleanly.
AgentAutomerges == phase = "pr_open" /\ reviewer = "zsensei" /\ mergedBy' = "agent" /\ phase' = "merged"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published>>

Done == phase \in {"merged", "draft_ready"} /\ UNCHANGED vars

Next == Classify \/ Plan \/ BrayanApprovesPlan \/ LaunchZninja \/ EditInlineWithReason
     \/ EditInlineNoReason \/ Review \/ ChecksAndRetro \/ OpenPR \/ DraftForBrayan
     \/ BrayanMerges \/ AgentAutomerges \/ Done

Spec == Init /\ [][Next]_vars

\* ---- Rules Brayan agreed to ----
NoEditBeforeClassify == edited => size /= "none"
BigNeedsApproval == (edited /\ size \in {"large", "critical"}) => approved
EditNeedsZninjaOrReason == edited => impl \in {"zninja", "inline_reason"}
MediumUpIndependentReview ==
  (phase \in {"pr_open", "merged", "draft_ready"} /\ size /= "small") => reviewer = "zsensei"
ClientNeverPublishes == repo = "client" => ~published
OnlyBrayanMerges == mergedBy \in {"none", "brayan"}
====
