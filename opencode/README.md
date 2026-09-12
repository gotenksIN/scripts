# OpenCode setup

## Overview

This directory holds the global OpenCode v2 configuration for this machine.
The files in `~/.config/opencode/` mostly symlink to or copy from this directory, so this repo is the source of truth.
Secrets stay local and never enter the repo.

| File | Purpose | Installed as |
| --- | --- | --- |
| `AGENTS.md` | Global agent instructions and workflow rules | Symlink at `~/.config/opencode/AGENTS.md` |
| `opencode.json` | Global config: plugins, subagents, websearch | Symlink at `~/.config/opencode/opencode.json` |
| `opencode.jsonc` | Provider template with `xxxx` placeholders | Not installed |
| `cli.json` | TUI settings: theme, keybinds, diffs | Copied to `~/.config/opencode/cli.json` |
| `README.md` | This guide | Not installed |

## Setup on a new machine

1. Clone this repo.

   ```sh
   git clone git@github.com:gotenksIN/scripts.git ~/scripts
   ```

2. Install the `opencode` binary with the update script.

   ```sh
   ~/scripts/opencode/update.sh
   ```

   The script downloads the latest release, verifies its checksum, and installs the binary to `~/.opencode/bin/opencode`.
   See [Updating OpenCode v2](#updating-opencode-v2).

3. Create the config directory.

   ```sh
   mkdir -p ~/.config/opencode
   ```

4. Symlink the global config files.
   Adjust the source paths if the clone lives elsewhere.

   ```sh
   ln -sf ~/scripts/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
   ln -sf ~/scripts/opencode/opencode.json ~/.config/opencode/opencode.json
   ```

5. Copy the TUI settings.
   Copy instead of symlinking because OpenCode writes interactive setting changes directly to this file.

   ```sh
   cp ~/scripts/opencode/cli.json ~/.config/opencode/cli.json
   ```

6. Install [Matt Pocock's skills](https://github.com/mattpocock/skills) globally for OpenCode.
   Install Bun first if `bunx` is missing.

   ```sh
   curl -fsSL https://bun.sh/install | bash
   export BUN_INSTALL="$HOME/.bun"
   export PATH="$BUN_INSTALL/bin:$PATH"
   ```

   ```sh
   bunx skills@latest add mattpocock/skills --skill '*' --global --agent opencode --yes
   ```

   The installer keeps one copy in `~/.agents/skills/` for OpenCode.

7. Start OpenCode once.
   It installs the configured plugins into `~/.cache/opencode/packages/` automatically.

   ```sh
   opencode
   ```

8. In each repository, run the setup skill once and answer its prompts.

   ```text
   /setup-matt-pocock-skills
   ```

9. On WSL2, enable WSLg for image paste.
   See the [Image paste on WSL2](#image-paste-on-wsl2) section.

10. On WSL2 with mirrored networking, set the service port below 49152.
   See the [Service port (WSL2 mirrored networking)](#service-port-wsl2-mirrored-networking) section.

11. Verify.

   ```sh
   opencode models
   opencode service status
   opencode api get /api/health
   ```

   In the TUI, check that the subagents `coder`, `reasoner`, `explore`, and `general` appear.
   Check that `/setup-matt-pocock-skills` appears in the command list.

Do not copy `~/.config/opencode/service.json` between machines.
OpenCode generates it and stores the service password in it.

## Applying updates to this machine

```sh
cd ~/scripts
git pull
opencode service restart
```

## Updating OpenCode v2

Run the update script.
It downloads the latest release, verifies its checksum, and swaps the binary atomically with rollback on failure.

```sh
~/scripts/opencode/update.sh
```

Pass a version as the first argument to install a specific one.

```sh
~/scripts/opencode/update.sh 1.2.3
```

The update warning "automatic update skipped: installation method not found" is expected.
The binary is installed by the script, not a package manager, so auto-update cannot detect the installation method.

## Image paste on WSL2

Paste an image into the prompt with Ctrl+V.
Screenshots copied in Windows arrive through WSLg as BMP data, and the TUI converts them to PNG automatically.

## Anti-slop lint skill

[anti-slop](https://github.com/dmmulroy/anti-slop) provides opinionated Oxlint rules that reject low-evidence TypeScript and JavaScript patterns.
Install the agent skill once per machine:

```sh
bunx skills@latest add dmmulroy/anti-slop --skill install-anti-slop --global --agent opencode --yes
```

The command installs into `~/.agents/skills/install-anti-slop`, which OpenCode loads as a global skill source.
Restart the service so the skill appears:

```sh
opencode service restart
```

Then ask the agent to install anti-slop in a repository.
The skill vendors the plugin under `tools/oxlint/anti-slop/`, registers it in the lint config, installs matching `oxlint` packages, and enables every rule at `error`.
The copied rules are yours to adjust.
See the upstream [README](https://github.com/dmmulroy/anti-slop) for the rule list and the manual path.

## Service port (WSL2 mirrored networking)

The service port is set to 4096.
WSL2 mirrored networking blocks the Windows dynamic port range 49152-65535, so the port must stay below 49152.

```sh
opencode service set port 4096
```
