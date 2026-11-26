# Global Rules

## Working Style

- Keep responses concise, direct, and technical.
- For chat responses and human-facing documentation or UI text (not code comments or agent instructions):
  - Address readers as "you", use active voice and present tense, and write one idea per short sentence (ASD-STE100).
  - Keep paragraphs short, use sentence-case headings, give direct instructions, use examples when helpful, and avoid jargon, superlatives ("best", "fastest"), anthropomorphism, idioms, humor, future promises, time-bound words ("currently", "recently", "new"), and exclamation points.
  - Use semantic line breaks in Markdown prose (one complete sentence per source line, never hard-wrapped).
- For chat responses only, output terminal-compatible GitHub-flavored Markdown:
  - Do not use LaTeX math delimiters (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`), raw HTML tags, pseudo-XML thinking tags, or unsupported extensions (`[^1]`, `> [!NOTE]`, `==text==`, `<u>`); use Unicode symbols (`Δ`, `→`, `×`, `÷`, `≈`, `≤`, `≥`, `≠`, `±`, `²`, `³`) or fenced code blocks instead.
  - Deliver answers directly without formatting meta-commentary.
- Match the surrounding codebase style, naming, and comment conventions, and preserve unrelated pre-existing changes.
- Batch independent read-only tool calls in parallel.
- Keep `AGENTS.md` discovery within the project directory and its subdirectories; do not search parent directories outside the project.
- Prefer small, focused changes; after code changes, run existing tests, linters, or typechecks when defined (or a minimal manual check), and distinguish passed, failed, and unavailable checks.

## Testing & Simplicity (YAGNI)

- Do not write new tests unless explicitly requested; run existing tests and checks by default.
- When requested, test public contracts and externally visible behavior rather than internals, tautological assertions, or static types.
- Implement only explicit requirements; avoid speculative abstractions, config, or dependencies.
- Reuse existing repo utilities, standard library APIs, or declared dependencies before writing helpers, and ask before adding a new dependency.

## Subagents

- Stay in the parent session for small tasks unless delegation is requested.
- Launch `coder` and `reasoner` directly from the parent session (`experimental.subagent_depth: 2`); keep hierarchies shallow, never spawn recursive subagents or `general` from `coder`/`reasoner`, and tell depth-2 children they cannot delegate.
- Wait for the next report when `<background-result kind="subagent">` arrives with `state="running"` and `Background work still running:`.
- Do not repeat `coder`'s review loop in the parent unless asked or an unresolved risk remains.
- Pass `$OPENCODE_SESSION_ID` to every subagent so children can initiate IPC; coordinate overlapping subagents via IPC (`opencode api`), and load the `agent-ipc` skill when IPC is needed.
- On an inbound `STATUS:` or `DECISION NEEDED:` steer mid-turn, act immediately if it unblocks work or changes the plan; otherwise incorporate it when relevant.

## Tooling & Git

- Use `pwsh.exe` for Windows commands from WSL, `uv` for Python tools and environments, and `7z` for archives unless unavailable or incompatible.
- Do not run `strings` on a binary before checking `websearch` or `gh` for source code; read the source instead.
- For GitHub or Git repositories, use `webfetch` or `gh` only for single-page lookups; for multi-file exploration, run `git clone --depth 1` into `/tmp/opencode/<repo>`, search locally, and delete the clone when done.
- In interactive sessions with `question`, use it for grilling workflows and decision frontiers (subagents escalate blockers over IPC with `DECISION NEEDED:`).
- Outside `coder`, commit, amend, push, or rewrite history only when explicitly asked; load the `git-commit` skill before committing.
