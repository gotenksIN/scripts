# OpenCode setup

## Overview

This directory stores the global OpenCode v2 configuration for this machine.
Files in `~/.config/opencode/` link to or copy from this repository.
Keep your API keys and credentials local; do not commit them to the repository.

| File | Purpose | Installed as |
| --- | --- | --- |
| `AGENTS.md` | Global agent instructions and workflow rules | Symlink at `~/.config/opencode/AGENTS.md` |
| `opencode.json` | Global configuration: plugins, subagents, and web search | Symlink at `~/.config/opencode/opencode.json` |
| `skills/` | Global on-demand skills (`agent-ipc`, `git-commit`) | Symlinks under `~/.config/opencode/skills/` |
| `opencode.jsonc` | Optional template for custom provider URLs or static API keys | Optional copy at `~/.config/opencode/opencode.jsonc` |
| `cli.json` | TUI settings: themes, keybindings, and diff displays | Copied to `~/.config/opencode/cli.json` |
| `README.md` | Setup and maintenance guide | Not installed |

## Setup on a fresh machine

Run `linux/common/setup.sh` (or your distribution's setup script, which calls it) and accept the OpenCode prompt:

```sh
bash ~/scripts/linux/common/setup.sh
```

The setup script handles installation and configuration:

- Installs OpenCode into `~/.opencode/bin/` with `--no-modify-path`.
- Symlinks `AGENTS.md`, `opencode.json`, and each directory in `skills/` into `~/.config/opencode/`, and copies `cli.json` when absent.
- Installs Bun into `~/.local/bin/`, installs `skills@latest` globally, symlinks `~/.local/bin/node`, and installs Matt Pocock's skills and `install-anti-slop` into `~/.agents/skills/`.
- Disables Topgrade's `github_cli_skills` step in `~/.config/topgrade.d/skills.toml`.
- Sets the service port to `4096` on WSL2, starts the background service, and verifies the installation.

### Manual steps after setup

Start `opencode` and connect your providers with `/connect`.
Use a Google API key for `opencode-websearch-addons`; the plugin rejects Google OAuth credentials.

If you need a custom `baseURL` or static `apiKey`, copy the optional `opencode.jsonc` template to `~/.config/opencode/opencode.jsonc`.
Delete or comment out unused provider blocks because each block enables its provider.
Replace the placeholders for the settings you need.
Omit `baseURL` to use the provider's default endpoint.
Omit `apiKey` if you use `/connect` for credentials.

Do not copy `~/.config/opencode/service.json` between machines.
OpenCode generates `service.json` automatically and stores the local service password inside it.

In the TUI, confirm that the subagents `coder`, `code-reviewer`, `reasoner`, `explore`, and `general` appear.
Confirm that `setup-matt-pocock-skills` appears in the skills list.

If you reinstall Bun, reinstall the global `skills` CLI with `bun install -g skills@latest`.
Reinstalling Bun removes global packages, so `skills` disappears and Topgrade skips the update.

## Skills

### Matt Pocock's skills

Load the `setup-matt-pocock-skills` skill once in each repository:

```text
Ask OpenCode to load the setup-matt-pocock-skills skill
```

Answer the interactive prompts to configure project-level instructions.

### Anti-slop linting skill

[anti-slop](https://github.com/dmmulroy/anti-slop) provides strict Oxlint rules for TypeScript and JavaScript codebases.
Ask the agent in your prompt to install anti-slop in a repository.
The skill copies plugins into `tools/oxlint/anti-slop/`, configures the linter, and enables rules as errors.
Refer to the upstream [README](https://github.com/dmmulroy/anti-slop) for rule descriptions and manual customization.

## Maintenance

### Updating OpenCode

Run the built-in update command:

```sh
opencode update
```

### Applying configuration updates

Reload OpenCode to apply configuration changes:

```sh
opencode reload
```

`opencode reload` applies configuration changes immediately without restarting active background processes.

## WSL2 considerations

### Image paste

Press `Ctrl+V` to paste images directly into the TUI prompt.
You need WSLg Wayland (`WAYLAND_DISPLAY` or `/mnt/wslg/runtime-dir`, plus `libwayland-client.so.0`) because WSLg does not pass clipboard images over X11.
WSLg passes images copied in Windows as BMP format.
The TUI converts them to PNG automatically.

### Service port for mirrored networking

WSL2 mirrored networking reserves the dynamic port range 49152-65535 on Windows.
`linux/common/setup.sh` sets the OpenCode service port to `4096` automatically on WSL2 so it stays below that range.

## Troubleshooting

### Providers not marked as connected in /connect

Configuring `settings.apiKey` in `~/.config/opencode/opencode.jsonc` enables the provider and lists its models in `/models`.
The `/connect` dialog checks saved credentials in `~/.local/share/opencode/opencode.db` (or environment variables), so config-only providers do not appear as connected in `/connect`.

To mark configured providers as connected in `/connect`, connect each provider with `/connect` or add rows to the `credential` table in `~/.local/share/opencode/opencode.db` using `uv` and Python (`sqlite3`):

1. Run `opencode` once so OpenCode initializes `~/.local/share/opencode/opencode.db`, then run `opencode service stop`.
2. Insert an active row into `credential` for each configured provider using its real `apiKey` from `opencode.jsonc`:

   | Column | Value |
   | --- | --- |
   | `id` | Unique string starting with `cred_` |
   | `integration_id` | Provider key from `opencode.jsonc` |
   | `label` | `"API key"` |
   | `value` | `{"type":"key","key":"<apiKey>"}` |
   | `active` | `1` |
   | `time_created` | Current epoch time in milliseconds |
   | `time_updated` | Current epoch time in milliseconds |

3. Run `opencode service start`.

Saved credentials in `opencode.db` take precedence over `settings.apiKey` in `opencode.jsonc`.
If you rotate an API key in `opencode.jsonc`, update or delete that provider's row in `credential` (or reconnect with `/connect`) so OpenCode uses the updated key.
