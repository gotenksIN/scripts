# Global Rules

## Working Style

- Keep responses concise, direct, and technical.
- Use ASD-STE100 Simplified Technical English for human-facing text.
  This includes documentation, commit messages, comments, user interfaces, and responses.
  Agent instructions, including `AGENTS.md`, do not need to follow this guidance.
- Follow Google developer documentation style guidance:
  write for the reader, use active voice and present tense, use sentence-case headings, and give direct instructions.
  Keep content concise, use inclusive language, define unfamiliar terms, and use examples when they improve clarity.
  Apply this guidance only to human-facing text, not to agent instructions.
- Use semantic line breaks in Markdown prose: put each complete sentence on its own source line and let the renderer wrap it.
- Do not hard-wrap Markdown prose at a fixed column or split a phrase only to meet a line-length limit.
- Prefer small, focused changes over broad refactors unless the user asks otherwise.
- Do not chain many commands into one shell line just to finish a task in a single run.
  The sandbox parser rejects commands that are too complex, so split exploration into short simple commands and run them one at a time.
- After code changes, run the project's existing tests, linter, or typecheck when those commands are defined.
  If none exist, do a minimal manual check of the changed behavior.
- Do not use LaTeX math syntax, math mode, dollar-sign delimiters (`$...$`, `$$...$$`), or LaTeX escape sequences (such as `\rightarrow`, `\Rightarrow`, `\times`, `\pm`, `\circ`, `\approx`, etc.) in direct terminal output or conversational responses.
  Standard TUI environments do not render LaTeX math markup in terminal output.
  Use standard Unicode characters (e.g., `→`, `⇒`, `×`, `±`, `°`, `≈`) or plain text for terminal output.
  In Markdown files, documentation, or other artifacts processed outside the terminal UI, rich Markdown and LaTeX math syntax are permitted.

## Subagent Routing

- Implementation: `coder-low` by default.
- `coder-high` only when the user explicitly requests it and the OpenAI quota is not exhausted for the current date.
  Quota details are under Provider Quota Handling.
- Read-only deep analysis: `reasoner`.
- Broad codebase or documentation search: `explore`.
- Non-code coordination: `general`.
- Stay in the parent session when the change is tiny and does not need a separate agent.
- Never spawn a `coder-*` agent from inside a `coder-*` agent.
  Finish the work or return to the parent.

## Tooling Preferences

- For web searches and technical research, always use `websearch_cited` to fetch grounded, up-to-date information with inline citations.
- For Python projects, always use `uv` for running tools, managing dependencies, and virtual environments unless the repository explicitly requires a different workflow.
- For GitHub repositories, issues, pull requests, releases, and file browsing, try `gh` CLI first for small or short lookups.
- For repositories hosted on GitHub or any other Git hosting service, clone the repository locally with `git` and use local searches and file reads.
  If `gh` fails, clone locally instead of switching to `webfetch`.
  For large repositories or exploration that requires many requests, clone locally from the start instead of repeatedly using `gh`.
  Use a directory under `/tmp/pi`, prefer a shallow clone when full history is not needed, and perform searches and file reads locally.
  If cloning fails, fall back to `webfetch`.
  Delete the temporary clone when the task ends, including after an unsuccessful task.
- Prefer `rg` over `grep` or `find` for shell-based searches.
  Prefer native file-search and content-search tools when they are available.
- Prefer `7z` for listing, testing, and extracting archives.
  Do not use `unzip` or `tar` when `7z` supports the archive format; use another tool only when `7z` is unavailable or incompatible, and state why.
- You may use `/tmp/pi` for temporary work outside the workspace; the bwrap-sandbox extension creates this scratch directory.
  Always delete temporary files and directories you create when the task ends.
  WSL does not use tmpfs, so leftover files in `/tmp/pi` persist on disk.

## Provider Quota Handling

- Pi does not inject the current date into the prompt.
  Assume the OpenAI provider is available at session start.
  If an OpenAI call fails with a quota exhaustion error, remember it and treat the quota as exhausted for the rest of the session.
- While the OpenAI quota is exhausted, do not use `coder-high`.
  Use `coder-low` for all implementation work.
- If the user explicitly requested `coder-high` and it is unavailable because the OpenAI quota is exhausted, stop the task and report that to the user.
  Do not silently fall back to another coder tier for that request.

## Git Workflow

- Never create commits unless the user explicitly asks for them.
- When the user requests per-task commits, commit each discrete task before starting the next one.
- Before every commit, run the exact full commands `git status`, `git diff`, and `git log -10`.
- Do not replace these required inspections with abbreviated variants such as `git status --short`, `git diff --stat`, or `git log --oneline`.
- Read the full commit messages from `git log -10`, including their bodies, and follow the repository's existing commit-message style.
- Stage only files that belong to the current task.
- Write concise, technical commit messages that explain what changed and why.
- Write the subject in the imperative mood, capitalize it, and do not end it with a period.
- Keep the subject near 50 characters and never longer than 72 characters.
- Separate the subject from the body with a blank line and wrap body text at 72 characters.
- Do not explain how the change works unless that detail gives needed context.
- Do not amend commits, push, or rewrite history unless the user explicitly asks.
  When the user explicitly asks, perform the requested operation and do not refuse solely because it amends commits, pushes, or rewrites history.
- Keep `.pi/` in `.gitignore`: it stores Pi runtime state such as the sandbox audit log (`.pi/sandbox-audit.jsonl`) and policy files.
  Never stage or commit files from `.pi/`.
