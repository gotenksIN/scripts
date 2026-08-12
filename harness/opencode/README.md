# OpenCode setup

## Overview

This directory holds the global OpenCode2 configuration for this machine.
The files in `~/.config/opencode/` mostly symlink to or copy from this directory, so this repo is the source of truth.
Secrets stay local and never enter the repo.

| File | Purpose | Installed as |
| --- | --- | --- |
| `AGENTS.md` | Global agent instructions and workflow rules | Symlink at `~/.config/opencode/AGENTS.md` |
| `opencode.json` | Global config: plugins, subagents, websearch | Symlink at `~/.config/opencode/opencode.json` |
| `opencode.jsonc` | Provider template with `xxxx` placeholders | Copied to `~/.config/opencode/opencode.jsonc` with real credentials |
| `cli.json` | TUI settings: theme, keybinds, diffs | Copied to `~/.config/opencode/cli.json` |
| `README.md` | This guide | Not installed |

## Setup on a new machine

Prerequisite: install the `opencode2` binary manually at `~/.opencode/bin/opencode2`.
See Updates are manual.

1. Clone this repo.

   ```sh
   git clone git@github.com:gotenksIN/scripts.git ~/scripts
   ```

2. Create the config directory.

   ```sh
   mkdir -p ~/.config/opencode
   ```

3. Symlink the global config files.
   Adjust the source paths if the clone lives elsewhere.

   ```sh
   ln -sf ~/scripts/harness/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
   ln -sf ~/scripts/harness/opencode/opencode.json ~/.config/opencode/opencode.json
   ```

4. Create the provider credentials file.
   Copy the template, then replace every `xxxx` with real values.

   ```sh
   cp ~/scripts/harness/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc
   ```

   This file contains API keys.
   Never commit the real values.
   The repo copy must keep the `xxxx` placeholders.

5. Copy the TUI settings.

   ```sh
   cp ~/scripts/harness/opencode/cli.json ~/.config/opencode/cli.json
   ```

6. Start OpenCode once.
   It installs the configured plugins into `~/.cache/opencode/packages/` automatically.

   ```sh
   opencode2
   ```

7. On WSL2 with mirrored networking, set the service port below 49152.
   See the Service port section.

8. Verify.

   ```sh
   opencode2 models
   opencode2 service status
   ```

   In the TUI, check that the subagents `coder-low`, `coder-high`, `reasoner`, `explore`, and `general` appear.

Do not copy `~/.config/opencode/service.json` between machines.
OpenCode generates it and stores the service password in it.

## Applying updates to this machine

```sh
cd ~/scripts
git pull
opencode2 service restart
```

## Service port (WSL2 mirrored networking)

The service port is set to 4096.
WSL2 mirrored networking blocks the Windows dynamic port range 49152-65535, so the port must stay below 49152.

```sh
opencode2 service set port 4096
```

## Updates are manual

The update warning "automatic update skipped: installation method not found" is expected.
The binary is installed manually at `~/.opencode/bin/opencode2`, so auto-update cannot detect the installation method.
Manually update the application when a new `next` version is announced.
