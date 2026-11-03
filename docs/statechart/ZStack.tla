---- MODULE ZStack ----
\* zStack as written in skills/zstack/SKILL.md (agent-workflow, option B: inline Medium+ still gets
\* zsensei; no agent merge). Each Agent* action is a step the skill forbids. It is enabled only when
\* the matching Barrier* constant is FALSE, i.e. when only skill text (no hook, CI check or
\* permission) stops it. A rule that holds with its barrier FALSE holds by design; one that holds only
\* with the barrier TRUE holds by text until that barrier exists.
EXTENDS TLC

CONSTANTS BarrierClassify, BarrierApproval, BarrierInlineReason, BarrierInlineSize, BarrierReview,
          BarrierClientPublish, BarrierMerge

Sizes == {"small", "medium", "large", "critical"}
Repos == {"personal", "client"}

VARIABLES phase, size, repo, impl, reviewer, approved, edited, published, mergedBy
vars == <<phase, size, repo, impl, reviewer, approved, edited, published, mergedBy>>

Init ==
  /\ phase = "requested" /\ size = "none" /\ repo \in Repos
  /\ impl = "none" /\ reviewer = "none" /\ approved = FALSE
  /\ edited = FALSE /\ published = FALSE /\ mergedBy = "none"

Classify == phase = "requested" /\ \E s \in Sizes : size' = s
  /\ phase' = "classified" /\ UNCHANGED <<repo, impl, reviewer, approved, edited, published, mergedBy>>

Plan == phase = "classified" /\ phase' = "planned"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published, mergedBy>>

BrayanApprovesPlan == phase = "planned" /\ size \in {"large", "critical"}
  /\ approved' = TRUE /\ phase' = "approved"
  /\ UNCHANGED <<size, repo, impl, reviewer, edited, published, mergedBy>>

ReadyToCode == (phase = "planned" /\ size \in {"small", "medium"}) \/ phase = "approved"

Code(how) == impl' = how /\ edited' = TRUE /\ phase' = "implemented"
  /\ UNCHANGED <<size, repo, reviewer, approved, published, mergedBy>>

LaunchZninja == ReadyToCode /\ Code("zninja")
EditInlineWithReason == ReadyToCode /\ size = "small" /\ Code("inline_reason")

AgentEditsBeforeClassify == ~BarrierClassify /\ phase = "requested" /\ edited' = TRUE
  /\ UNCHANGED <<phase, size, repo, impl, reviewer, approved, published, mergedBy>>
AgentEditsBeforeApproval == ~BarrierApproval /\ phase = "planned" /\ size \in {"large", "critical"}
  /\ Code("zninja")
AgentEditsInlineNoReason == ~BarrierInlineReason /\ ReadyToCode /\ Code("inline_noreason")
AgentEditsInlineMediumUp == ~BarrierInlineSize /\ ReadyToCode /\ size /= "small" /\ Code("inline_reason")

\* Option B: review follows the size on both paths.
Review == phase = "implemented" /\ phase' = "reviewed"
  /\ reviewer' = (IF size = "small" THEN "diff_read" ELSE "zsensei")
  /\ UNCHANGED <<size, repo, impl, approved, edited, published, mergedBy>>

AgentSkipsReview == ~BarrierReview /\ phase = "implemented" /\ size /= "small"
  /\ reviewer' = "self_check" /\ phase' = "reviewed"
  /\ UNCHANGED <<size, repo, impl, approved, edited, published, mergedBy>>

ChecksAndRetro == phase = "reviewed" /\ phase' = "retro_done"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published, mergedBy>>

OpenPR == phase = "retro_done" /\ repo = "personal" /\ published' = TRUE /\ phase' = "pr_open"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, mergedBy>>

DraftForBrayan == phase = "retro_done" /\ repo = "client" /\ phase' = "draft_ready"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published, mergedBy>>

AgentPublishesClientPR == ~BarrierClientPublish /\ phase = "retro_done" /\ repo = "client"
  /\ published' = TRUE /\ phase' = "pr_open"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, mergedBy>>

BrayanMerges == phase = "pr_open" /\ mergedBy' = "brayan" /\ phase' = "merged"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published>>

AgentMerges == ~BarrierMerge /\ phase = "pr_open" /\ mergedBy' = "agent" /\ phase' = "merged"
  /\ UNCHANGED <<size, repo, impl, reviewer, approved, edited, published>>

Done == phase \in {"merged", "draft_ready"} /\ UNCHANGED vars

Next == Classify \/ Plan \/ BrayanApprovesPlan \/ LaunchZninja \/ EditInlineWithReason
     \/ AgentEditsBeforeClassify \/ AgentEditsBeforeApproval \/ AgentEditsInlineNoReason \/ AgentEditsInlineMediumUp
     \/ Review \/ AgentSkipsReview \/ ChecksAndRetro \/ OpenPR \/ DraftForBrayan
     \/ AgentPublishesClientPR \/ BrayanMerges \/ AgentMerges \/ Done

Spec == Init /\ [][Next]_vars

NoEditBeforeClassify == edited => size /= "none"
BigNeedsApproval == (edited /\ size \in {"large", "critical"}) => approved
EditNeedsZninjaOrReason == edited => impl \in {"none", "zninja", "inline_reason"}
MediumUpByZninja == (edited /\ impl = "inline_reason") => size = "small"
MediumUpIndependentReview ==
  (phase \in {"pr_open", "merged", "draft_ready"} /\ size /= "small") => reviewer = "zsensei"
ClientNeverPublishes == repo = "client" => ~published
OnlyBrayanMerges == mergedBy \in {"none", "brayan"}
====
