---
name: git-commit
description: Commit workflow, commit_context baseline capture, opencode-commit-guard rules, and repository commit message formatting.
---

# Git Commit Workflow

- When committing multi-task work, commit each discrete task before starting the next one.
- Capture commit context before the first commit in each session and worktree when `commit_context` is available (via Code Mode `search({ namespace: "commit_context" })`, then `tools.commit_context(...)`).
  Follow its returned capture instructions immediately in the indicated workdir and require `"Frozen commit baseline"` before committing.
  Call it with `{ refresh: true }` after a branch switch, a signing-settings change, or a change to commit instructions.
- Always run the exact full commands `git status` and `git diff` before committing or amending.
  Do not replace these required inspections with abbreviated variants such as `git status --short` or `git diff --stat`.
- If `commit_context` is unavailable and commit guard is not active, fall back to running the exact full commands `git status`, `git diff`, and `git log -10`, and read the full commit messages including their bodies and trailers.
  If commit guard is active, resolve the capture failure before committing; `git log` cannot provide its required baseline.
- Stage only files that belong to the current task.
- Run `git commit` directly in the target worktree.
  Commit guard rejects `git -C`, Git directory or environment overrides, `-F <file>`, `--trailer`, and shell expansion in commit messages.
- Format commit messages per the repository conventions:
  - Subject format: `<scope>: <Capitalized summary>`, with a lowercase scope derived from the changed component or directory.
  - Use the imperative mood and do not end the subject with a period.
  - Keep the subject near 50 characters and never longer than 72 characters.
  - Add a concise, technical body when the subject does not provide enough context: explain what changed and why (and how only when needed), separated by a blank line and wrapped at 72 characters.
  - Pass multi-line messages inline with `$'…'` and literal `\n` escapes, for example `git commit -m $'scope: Subject\n\nBody line one.\nBody line two.'`, or with a single-quoted stdin heredoc (`git commit -F - <<'EOF'`).
    Use `git commit --amend --no-edit` to retain a commit message when authorized to amend.
- Decide signoff from the repository's signing configuration:
  - Use the signing settings from `"Frozen commit baseline"` when available, or check once per session with `git config commit.gpgsign` and `git config user.signingkey`.
  - Add `-s` or `--signoff` when effective `commit.gpgsign=true`; omit it when `false` or unset unless the user or repository requires it.
  - Signoff (`Signed-off-by`) is separate from cryptographic signing, which follows `commit.gpgsign=true` and `user.signingkey`.
