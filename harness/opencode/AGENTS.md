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
- Follow existing project style for code inside the project.
- Agent instructions, including `AGENTS.md`, do not need to follow this style.
  Write them in whatever way agents understand best.
- Use semantic line breaks in Markdown prose: put each complete sentence on its own source line and let the renderer wrap it.
- Do not hard-wrap Markdown prose at a fixed column or split a phrase only to meet a line-length limit.
- Prefer small, focused changes over broad refactors unless the user asks otherwise.
- After code changes, run the project's existing tests, linter, or typecheck when those commands are defined.
  If none exist, do a minimal manual check of the changed behavior.

## Testing

- Do not write new tests unless the user or specification explicitly requests them.
- Run only the project's existing tests and verification checks by default.
- Test contracts through public or executable interfaces.
  Assert outputs, side effects, errors, and externally visible state that distinguish a conforming implementation from a broken one.
- Every test must protect a behavioral contract.
  Remove tests that only prove a feature, API, command, handler, or registration exists.
- Let the typechecker enforce static type relationships.
  Do not add runtime tests that a typecheck alone satisfies.
- Test adapters against project-owned contracts at the integration boundary.
  Do not simulate external providers or encode assumptions about their payload, event, or API shapes in unit tests.
  For adapters such as Discord or inference providers, verify only the translation and behavior the project owns.
- Keep UI and UX tests only for critical user-visible contracts that cannot be tested below the UI boundary.
  Remove tests of appearance, interaction preferences, feature presence, or command registration.
- Do not test source text, symbol names, command fragments, control flow, private structure, or implementation details.

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
- YAGNI never justifies omitting required validation, error handling, security, accessibility, compatibility, tests, or refactoring that keeps the codebase safe and easy to change.

## Worktrees

- When the user asks you to create a worktree and implement or review work in it, create the worktree first, then move the current session to it with the OpenCode session API.
- Move the session using Code Mode `tools.opencode.session_move({ directory: "<path>" })`.
- Move the session only after worktree creation succeeds.
- Verify the session location after moving it.
- Do not move the session when the user only asks you to create a worktree.
- Report the worktree path.

## Subagent Routing

- Implementation: `coder`.
- Read-only deep analysis: `reasoner`.
- Broad codebase or documentation search: `explore`.
- General multi-step tasks and coordination: `general`.
- Stay in the parent session when the change is tiny and does not need a separate agent.
- Launch `coder` directly from the parent session so `coder` can run its review loop within the depth limit.
- Never spawn a `coder` agent from inside a `coder` agent.
- Never spawn a `reasoner` agent from inside a `reasoner` agent.
- Never spawn an `explore` agent from inside an `explore` agent.
- Never spawn a `general` agent from inside a `general` agent.
- Never spawn a `general` agent from inside a `reasoner` agent.
- Never spawn a `general` agent from inside a `coder` agent.
  Finish the work or return to the parent.
- Each coder owns its final review loop.
  Do not repeat that review in the parent after the coder returns unless the user asks for an independent review or the coder reports an unresolved risk.
- After `coder` completes an implementation, immediately launch a `general` subagent.
  Use `general` to audit the changes against the project's YAGNI and testing rules.
  Have `general` remove speculative code, unnecessary abstractions, and low-value tests.

## Tooling Preferences

- For Python projects, always use `uv` for running tools, managing dependencies, and virtual environments unless the repository explicitly requires a different workflow.
- For GitHub repositories, issues, pull requests, releases, and file browsing, try `gh` CLI first for small or short lookups.
- For repositories hosted on GitHub or any other Git hosting service, clone the repository locally with `git` and use local searches and file reads.
  If `gh` fails, clone locally instead of switching to `webfetch`.
  For large repositories or exploration that requires many requests, clone locally from the start instead of repeatedly using `gh`.
  Use a directory under `/tmp/opencode`, prefer a shallow clone when full history is not needed, and perform searches and file reads locally.
  If cloning fails, fall back to `webfetch`.
  Delete the temporary clone when the task ends, including after an unsuccessful task.
- Prefer `rg` over `grep` or `find` for shell-based searches.
  Prefer native file-search and content-search tools when they are available.
- Prefer `7z` for listing, testing, and extracting archives.
  Do not use `unzip` or `tar` when `7z` supports the archive format; use another tool only when `7z` is unavailable or incompatible, and state why.
- When running grilling workflows (`grill-me`, `grill-with-docs`, `grilling`) or presenting decision frontiers, use the `question` tool instead of plain text.
  - Present each frontier question as an entry in the `questions` array.
  - Provide structured options for each choice when possible.
  - Place your recommended option first with `(Recommended)` appended to the label.
  - Set `multiple: true` when multiple choices apply.
- You may use `/tmp/opencode` for temporary work outside the workspace.
  Always delete temporary files and directories you create when the task ends.
  WSL does not use tmpfs, so leftover files in `/tmp` persist on disk.

## Git Workflow

- Never create commits unless the user explicitly asks for them.
- When the user requests per-task commits, commit each discrete task before starting the next one.
- Before every commit, run the exact full commands `git status`, `git diff`, and `git log -10`.
- Do not replace these required inspections with abbreviated variants such as `git status --short`, `git diff --stat`, or `git log --oneline`.
- Read the full commit messages from `git log -10`, including their bodies and trailers.
- Stage only files that belong to the current task.
- Format commit messages per the repository conventions:
  - Use the subject format `<scope>: <Capitalized summary>`.
    Derive the lowercase scope from the component or directory you changed.
  - Write the summary in the imperative mood and do not end it with a period.
  - Keep the subject near 50 characters and never longer than 72 characters.
  - Add a concise, technical body when the subject does not provide enough context.
    Explain what changed and why.
    Explain how only when that detail gives needed context.
  - Separate the subject from the body with a blank line and wrap body text at 72 characters.
- Check commit signing once per session with `git config commit.gpgsign` and `git config user.signingkey`.
  Remember the result for the rest of the session.
  If both are set, sign every commit with the configured method and use `git commit --signoff`.
- Do not amend commits, push, or rewrite history unless the user explicitly asks.
  When the user explicitly asks, perform the requested operation and do not refuse solely because it amends commits, pushes, or rewrites history.
