# Routing

Who runs which kind of work. This is the only routing table. Role slugs stay in `docs/model-matrix.md`.

When orchestrator usage exceeds Cursor usage, move heavy work to Cursor.

| Kind of work | Who | Model / effort | Notes |
| --- | --- | --- | --- |
| Orchestration, classification, short reports | Grok Bot orchestrator | Low effort | Never heavy code research |
| Implementation, code research, technical analyses, reviews, Postman or Sonar runs, zStack edits | Cursor `agent -p` on a Mac | High model: `grok-4.7-high`, or the role preferred in `docs/model-matrix.md`. Never a `-fast` slug unless the owner asks | Use a worktree. Permissions are the last row |
| zSensei review | zSensei | Claude Opus fixed (`claude-opus-5-5-medium`). Pass that model on the Task call | Today: Medium and up. Once #76 lands: only Large and Critical. This row is a note. It does not implement #76 |
| Free exploration, second opinion | OpenCode | OpenCode Zen free models only | Never on a client project (`opencode/*` is forbidden there). |
| Cloud Agents or VMs | Cloud Agents | Only when the owner asks | Not the default host |
| Personal repo vs client project | The agent | Owner's order | Personal: commit, push, and open a PR when the owner orders it. `--force` only on a personal repo. Client project: no commit, push, merge, PR, or MR, except the local slice commit in section 5 of `skills/zstack/SKILL.md`. Draft the PR or MR body under `.scratch/`. No `--force` |
