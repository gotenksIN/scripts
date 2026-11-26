---
name: agent-ipc
description: Send and read inter-agent messages over OpenCode IPC (opencode api) for mid-run findings, blockers, decisions, and steering.
---

# Inter-agent messaging

Use inter-agent messaging (IPC) for actionable mid-run findings, blockers, decisions, steering, dependency handoffs, and coordination across sessions or worktrees.

- Subagents deliver their turn results to their parent automatically via `<background-result kind="subagent">` reports; do not duplicate normal completion reports over IPC.
  Use IPC only for mid-run updates or coordination with peers and other sessions.
- Use the `opencode api` CLI for all calls; it handles service discovery and authentication.
  Do not construct raw HTTP requests unless you already hold the server URL and token.
- Check the service: `opencode service status`, `opencode api get /api/info`.
- List active sessions: `opencode api get /api/session/active`.
  Session IDs start with `ses_`; the current session ID is in `$OPENCODE_SESSION_ID`.
- Send a message: `opencode api post /api/session/<sessionID>/prompt --data '{"text":"STATUS: ses_<senderID> ...","delivery":"steer"}'`.
  - Use `"delivery":"steer"` by default for subagent coordination: actionable findings, dependency handoffs, blockers, decisions, and corrections.
    It injects the message into a running session mid-turn so the recipient can assess it before continuing with stale assumptions.
  - Use `"delivery":"queue"` only for non-actionable context the recipient needs later and that can safely wait until its next turn boundary.
- Read recent messages: `opencode api get '/api/session/<sessionID>/message?limit=8&order=desc'`.
- Inspect pending input: `opencode api get /api/session/<sessionID>/inbox`.
  An empty inbox means earlier messages were already delivered.
- Include the sender session ID and a `STATUS:` or `DECISION NEEDED:` prefix in each message so the reader can attribute and reply.
- Send one concise, content-rich message when it changes what the recipient can or should do.
  Include the finding or result and its effect on the recipient's work.
  Omit routine progress, acknowledgements, and conversational replies.
- For sending and reading messages, use only the session `prompt`, `inbox`, and `message` endpoints.
  Never call mutating endpoints (`delete`, `revert`, `interrupt`, `move`) against another session.
- Wrapper scripts that hide the JSON payload are fine; keep them small and pass the session ID and text as arguments.
