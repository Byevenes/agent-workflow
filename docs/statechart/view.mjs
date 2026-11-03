const P = {requested:"Request received", classified:"Classified (size printed)", planned:"Planned (.scratch spec)",
 approved:"Plan approved by Brayan", implemented:"Code written", reviewed:"Reviewed", retro_done:"Checks green + retro",
 pr_open:"PR open (zpr body)", merged:"Merged", draft_ready:"Client: PR body drafted in .scratch"};
const I = {zninja:"by zNinja", inline_reason:"inline, reason recorded", inline_noreason:"inline, no reason"};
const R = {zsensei:"zSensei", self_check:"self-check only", diff_read:"diff read"};
export const title = "zStack workflow (agent-workflow @ d447961)";
export const state = (v) => {
  let s = P[v.phase];
  if (["implemented","reviewed","retro_done","pr_open","merged","draft_ready"].includes(v.phase)) s += `, ${I[v.impl]}`;
  if (["reviewed","retro_done","pr_open","merged","draft_ready"].includes(v.phase)) s += `, ${R[v.reviewer]}`;
  if (v.phase === "merged") s += v.mergedBy === "agent" ? ", by the agent" : ", by Brayan";
  return s;
};
export const group = (v) => ["implemented","reviewed"].includes(v.phase) ? "code" :
  ["retro_done","pr_open","merged","draft_ready"].includes(v.phase) ? "deliver" : "plan";
export const colors = { plan: "blue", code: "orange", deliver: "teal" };
const L = { Classify:"zStack classifies the task", Plan:"zgrill / zspec / ztickets plan it",
 BrayanApprovesPlan:"Brayan approves the plan [Large or Critical]", LaunchZninja:"zNinja writes the code",
 EditInlineWithReason:"the agent codes inline and writes the reason", EditInlineNoReason:"the agent codes inline without a reason",
 Review:"the change is reviewed", ChecksAndRetro:"pre-commit, CI and zretro pass", OpenPR:"zpr opens the PR [personal repo]",
 DraftForBrayan:"zpr drafts the body [client repo]", BrayanMerges:"Brayan merges", AgentAutomerges:"the agent automerges [pure refactor]", Done:null };
export const step = (a) => L[a] ?? a;
