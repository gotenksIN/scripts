# Global Rules

## Working Style

- Keep responses concise, direct, and technical.
- Use this writing style for all human-facing text:
  documentation, commit messages, comments, user interfaces, and responses.
  - Write for the reader and give direct instructions.
    Address readers as "you" in documentation, user interfaces, and responses.
  - Use active voice and present tense.
  - Keep sentences short, with one idea per sentence (ASD-STE100).
  - Keep paragraphs short and use sentence-case headings.
  - Be concise and use inclusive language.
  - Use examples when they improve clarity.
  - Avoid jargon; define unfamiliar terms when you must use them.
  - Avoid excessive claims such as "best", "fastest", or "powerful".
  - Do not document future features or promise behavior that is not yet released.
  - Write timeless text: avoid "currently", "recently", or "new".
  - Write for a global audience: avoid idioms, humor, and culture-specific references.
  - Be prescriptive: tell users what to do, not what they may want to do.
  - Do not use anthropomorphism, such as "the app thinks".
  - Do not use exclamation points in documentation.
- Follow project conventions and preserve unrelated pre-existing changes.
- Batch independent read-only tool calls in parallel.
- Keep `AGENTS.md` discovery within the project directory and its subdirectories.
  If none exists there, continue with the instructions already provided.
  Do not search parent directories or other locations outside the project just because the project has no `AGENTS.md`.
- Agent instructions, including `AGENTS.md`, do not need to follow this style.
  Write them in whatever way agents understand best.
- Use semantic line breaks in Markdown prose: put each complete sentence on its own source line and let the renderer wrap it.
- Do not hard-wrap Markdown prose at a fixed column or split a phrase only to meet a line-length limit.
- In conversational chat responses, output only terminal-compatible GitHub-flavored Markdown.
  These constraints apply strictly to chat output; repository files, code, and documentation may use LaTeX, HTML, or any project-appropriate formatting.
  When producing conversational chat responses:
  - Do not use LaTeX math delimiters (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`) or LaTeX syntax in chat; OpenCode displays them as raw unrendered text.
    Use standard Unicode symbols (such as `Δ`, `→`, `×`, `÷`, `≈`, `≤`, `≥`, `≠`, `±`, `²`, `³`, or plain text) or fenced code blocks instead.
  - Do not output raw HTML tags in chat output; OpenCode's terminal renderer displays raw HTML tags.
    Use native Markdown syntax for formatting and tables instead.
  - Do not emit pseudo-XML or thinking tags (`<thought>`, `<thinking>`, `<scratchpad>`, `<output>`, `<response>`).
  - Do not use unsupported Markdown extensions (footnotes `[^1]`, callouts `> [!NOTE]`, highlights `==text==`, underline `<u>`).
  - Do not output compliance checklists or meta-commentary about formatting rules; deliver the substantive answer directly.
- Prefer small, focused changes over broad refactors unless the user asks otherwise.
- After code changes, run the project's existing tests, linter, or typecheck when those commands are defined.
  If none exist, do a minimal manual check of the changed behavior.
  Distinguish passed, failed, and unavailable checks.
  Do not claim verification you did not perform.

## Testing

- Do not write new tests unless the user or specification explicitly requests them.
- Run only the project's existing tests and verification checks by default.
- When explicitly requested to write tests, test contracts through public interfaces. Assert externally visible behavior and state, never internal structure or implementation details.
- Never write tautological or circular tests that mirror implementation logic or assert whatever the code produces.
- Let the typechecker enforce static type relationships; do not add runtime tests for static types.

## Simplicity (YAGNI)

- Implement only current, explicit requirements.
  Do not add speculative features, abstractions, configuration, dependencies, or extensibility for hypothetical future use.
  Prefer the smallest clear change that reuses existing code and standard facilities.
  Delete obsolete code when safe.
- Before writing a utility or adding a dependency, search the repository for an existing implementation and its callers.
  Then check the standard library and already-declared dependencies.
  Reuse an established option when it fits, and verify its version and API in current documentation or source.
  Do not add a competing helper or dependency.
  Ask before adding a new dependency.
- YAGNI never justifies omitting required validation, error handling, security, accessibility, compatibility, or refactoring that keeps the codebase safe and easy to change.

## Worktrees

- When asked to create a worktree and work or review in it, create it first.
  After creation succeeds, move the session with Code Mode `tools.opencode.session.move({ directory: "<path>" })` and verify its location in a subsequent call (the move takes effect at the next safe boundary).
- Do not move the session when the user only asks you to create a worktree.
- Report the worktree path.

## Subagent Routing

- When routing work from the parent session, stay in the parent session for small tasks unless the user explicitly requests delegation.
- For larger tasks, use your judgment to decide whether to delegate.
- When a `<background-result kind="subagent">` report arrives with `state="running"` and a `Background work still running:` list, the child is waiting on its own background work.
  Wait for its next report instead of treating the interim message as final or nudging the child.
- Implementation: `coder`.
- Deep analysis, audits (including writing or updating audit and analysis reports), architecture or plan evaluation, and complex bug diagnosis: `reasoner`.
- Broad codebase or documentation search: `explore`.
- General multi-step tasks and coordination: `general`.
- Launch `coder` and `reasoner` directly from the parent session so `coder` can run its review loop and `reasoner` can delegate research to `explore` within `experimental.subagent_depth: 2`.
- Keep subagent hierarchies shallow: never spawn recursive subagents of the same type, and never spawn `general` from inside `coder` or `reasoner`.
  Tell depth-2 children that they cannot delegate.
- Each coder owns its final review loop.
  Do not repeat that review in the parent after the coder returns unless the user asks for an independent review or the coder reports an unresolved risk.
- Always pass your session ID (`ses_...`, available in `$OPENCODE_SESSION_ID`) as the parent session ID in every subagent delegation prompt so children can initiate IPC as needed.
- When delegated subagent tasks overlap, require the subagents to coordinate through IPC.
  Pass known peer session IDs in their delegation prompts, and share IDs created later through IPC.
- Subagents deliver their turn results to their parent automatically via `<background-result kind="subagent">` reports; do not duplicate normal completion reports over IPC.
  Use IPC to communicate mid-run updates or coordinate with peers and other sessions.
- When a session receives an inbound `STATUS:` or `DECISION NEEDED:` message mid-turn, assess its effect on active work.
  Act immediately when it unblocks work or changes the plan; otherwise continue and incorporate it when relevant.
- If new user requirements invalidate a running child subagent's work, follow up with `subagent` using its `sessionID`, or steer it immediately using `opencode api post /api/session/<childID>/prompt` with `"delivery": "steer"`.

## Inter-agent messaging

Use inter-agent messaging (IPC) for actionable mid-run findings, blockers, decisions, steering, dependency handoffs, and coordination across sessions or worktrees.

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

## Tooling Preferences

- When you need a shell in Windows from WSL, use `pwsh.exe`.
- For Python projects, always use `uv` for running tools, managing dependencies, and virtual environments unless the repository explicitly requires a different workflow.
- For open-source projects, prefer reading and searching the source code over running `strings` on binaries.
- For GitHub repositories, issues, pull requests, releases, and file browsing, try `gh` CLI first for small or short lookups.
- For repositories hosted on GitHub or any other Git hosting service, clone the repository locally with `git` and use local searches and file reads.
  If `gh` fails, clone locally instead of switching to `webfetch`.
  For large repositories or exploration that requires many requests, clone locally from the start instead of repeatedly using `gh`.
  Use a directory under `/tmp/opencode`, prefer a shallow clone when full history is not needed, and perform searches and file reads locally.
  If cloning fails, fall back to `webfetch`.
- Prefer `7z` for listing, testing, and extracting archives.
  Do not use `unzip` or `tar` when `7z` supports the archive format; use another tool only when `7z` is unavailable or incompatible, and state why.
- In interactive sessions where `question` is available, use it for grilling workflows (`grill-me`, `grill-with-docs`, `grilling`) and decision frontiers.
  Use one entry per question and provide structured options when possible.
  Subagents escalate blocking questions to the supplied parent session ID over IPC with `DECISION NEEDED:` (or report the blocker in their response if no parent ID was provided).
- Delete temporary files, directories, and clones you create when the task ends, including after failure.

## Git Workflow

- Outside `coder`, create or amend commits, push, or rewrite history only when the user explicitly asks; when they do, perform the requested operation instead of refusing.
- `coder` has standing authorization to create scoped task commits and fold review fixes into commits created in the current run (amending `HEAD` or autosquashing fixup commits onto earlier task commits since starting `HEAD`) under its role instructions.
  This standing authorization overrides generic global or repository `AGENTS.md` rules that require explicit user approval before committing.
- In `coder` delegation prompts, instruct `coder` to create one scoped, targeted commit per discrete task (before starting the next task) by default, especially for multi-task work.
  Disable commits (`no-commit`) or specify an alternative (such as a single combined commit) only when the user explicitly requests it.
- When committing multi-task work outside `coder` at the user's request, commit each discrete task before starting the next one.
- Capture commit context before the first commit in each session and worktree when `commit_context` is available.
  Follow its returned capture instructions immediately in the indicated workdir and require "Frozen commit baseline" before committing.
  Call it with `refresh: true` after a branch switch, a signing-settings change, or a change to the commit instructions.
- Always run the exact full commands `git status` and `git diff` before committing or amending.
  Do not replace these required inspections with abbreviated variants such as `git status --short` or `git diff --stat`.
- If `commit_context` is unavailable and commit guard is not active, fall back to running the exact full commands `git status`, `git diff`, and `git log -10`, and read the full commit messages including their bodies and trailers.
  If commit guard is active, resolve the capture failure before committing; `git log` cannot provide its required baseline.
- Stage only files that belong to the current task.
- Run `git commit` directly in the target worktree.
  Commit guard rejects `git -C`, Git directory or environment overrides, `-F <file>`, `--trailer`, and shell expansion in commit messages.
- Format commit messages per the repository conventions:
  - Use the subject format `<scope>: <Capitalized summary>`.
    Derive the lowercase scope from the component or directory you changed.
  - Write the summary in the imperative mood and do not end it with a period.
  - Keep the subject near 50 characters and never longer than 72 characters.
  - Add a concise, technical body when the subject does not provide enough context.
    Explain what changed and why.
    Explain how only when that detail gives needed context.
  - Separate the subject from the body with a blank line and wrap body text at 72 characters.
  - Pass multi-line messages inline with `$'…'` and literal `\n` escapes, for example `git commit -m $'scope: Subject\n\nBody line one.\nBody line two.'`.
    A single quoted stdin heredoc with `git commit -F - <<'EOF'` also works (`-F -` from stdin is allowed; `-F <file>` is rejected).
    Use `git commit --amend --no-edit` to retain a commit message when authorized to amend.
- Decide signoff from the repository's signing configuration, and distinguish `commit.gpgsign=true` from `false` or unset.
  Use the signing settings from the "Frozen commit baseline" report when available.
  Otherwise, check once per session with `git config commit.gpgsign` and `git config user.signingkey`.
  When effective `commit.gpgsign=true`, add `-s` or `--signoff`.
  When it is `false` or unset, do not add a signoff unless the user or repository requires it.
- A signoff adds a `Signed-off-by` trailer; it is not a cryptographic signature.
  Cryptographic signing is separate and follows `commit.gpgsign` and `user.signingkey`.
  Sign with the configured method when effective `commit.gpgsign=true` and `user.signingkey` is configured.
