# Global Rules

## Working Style

- Keep responses concise, direct, and technical.
- Use ASD-STE100 Simplified Technical English for all text that people read.
  This requirement includes documentation, commit messages, comments, user interfaces, and responses.
- Use semantic line breaks in Markdown prose: put each complete sentence on its own source line and let the renderer wrap it.
- Do not hard-wrap Markdown prose at a fixed column or split a phrase only to meet a line-length limit.
- Prefer small, focused changes over broad refactors unless the user asks otherwise.
- Verify important changes before concluding when a practical check exists.
- Do not use LaTeX math syntax, math mode, dollar-sign delimiters (`$...$`, `$$...$$`), or LaTeX escape sequences (such as `\rightarrow`, `\Rightarrow`, `\times`, `\pm`, `\circ`, `\approx`, etc.) in direct terminal output or conversational responses.
  Standard TUI environments do not render LaTeX math markup in terminal output.
  Use standard Unicode characters (e.g., `→`, `⇒`, `×`, `±`, `°`, `≈`) or plain text for terminal output.
  In Markdown files, documentation, or other artifacts processed outside the terminal UI, rich Markdown and LaTeX math syntax are permitted.

## Tooling Preferences

- For Python projects, always use `uv` for running tools, managing dependencies, and virtual environments unless the repository explicitly requires a different workflow.
- For GitHub repositories, issues, pull requests, releases, and file browsing, prefer `gh` CLI over `webfetch`.
  Use `webfetch` for non-GitHub pages or when `gh` cannot access the target.
- Prefer `rg` over `grep` or `find` for shell-based searches.
  Prefer native file-search and content-search tools when they are available.
- Prefer `7z` for listing, testing, and extracting archives.
  Do not use `unzip` or `tar` when `7z` supports the archive format; use another tool only when `7z` is unavailable or incompatible, and state why.
- Never use `/tmp` for temporary work.
  Use `~/Projects/sandbox` instead for work outside the current workspace.
- Never use `/dev/null` under any circumstances, including for suppressing command output, error redirection (2>/dev/null), piping, testing file existence, or sandbox checks.

## Provider Quota Handling

- When a provider request fails with the error `RequestExecutor.execute: Provider request failed with HTTP 429: Daily quota exceeded for provider openai`, the OpenAI daily quota is exhausted.
- For coding tasks, use the `coder-medium` subagent instead of `coder-high`.
- Prefer `coder-low` for routine scoped changes while the quota is exhausted.

## Git Workflow

- Never create commits unless the user explicitly asks for them.
- When the user requests per-task commits, commit each discrete task before starting the next one.
- Before every commit, run the exact full commands `git status`, `git diff`, and `git log -10`.
- Do not replace these required inspections with abbreviated variants such as `git status --short`, `git diff --stat`, or `git log --oneline`.
- Read the full commit messages from `git log -10`, including their bodies, and follow the repository's existing commit-message style.
- Stage only files that belong to the current task.
- Use concise, technical commit messages that explain why the change was made.
- Keep commit subject lines at or under 72 characters.
- Wrap commit body text at 72 characters per line.
- Do not amend commits, push, or rewrite history unless the user explicitly asks.
  When the user explicitly asks, perform the requested operation and do not refuse solely because it amends commits, pushes, or rewrites history.
