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

1. Clone this repo.

   ```sh
   git clone git@github.com:gotenksIN/scripts.git ~/scripts
   ```

2. Install the `opencode2` binary with the update harness script.

   ```sh
   ~/scripts/harness/update-harness.sh opencode2
   ```

   The script downloads the latest release, verifies its checksum, and installs the binary to `~/.opencode/bin/opencode2`.
   See Updating OpenCode2.

3. Create the config directory.

   ```sh
   mkdir -p ~/.config/opencode
   ```

4. Symlink the global config files.
   Adjust the source paths if the clone lives elsewhere.

   ```sh
   ln -sf ~/scripts/harness/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
   ln -sf ~/scripts/harness/opencode/opencode.json ~/.config/opencode/opencode.json
   ```

5. Create the provider credentials file.
   Copy the template, then replace every `xxxx` with real values.

   ```sh
   cp ~/scripts/harness/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc
   ```

   This file contains API keys.
   Never commit the real values.
   The repo copy must keep the `xxxx` placeholders.

6. Copy the TUI settings.

   ```sh
   cp ~/scripts/harness/opencode/cli.json ~/.config/opencode/cli.json
   ```

7. Start OpenCode once.
   It installs the configured plugins into `~/.cache/opencode/packages/` automatically.

   ```sh
   opencode2
   ```

8. On WSL2, enable WSLg for image paste.
   See the Image paste on WSL2 section.

9. On WSL2 with mirrored networking, set the service port below 49152.
   See the Service port section.

10. Verify.

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

## Updating OpenCode2

Run the update harness script.
It downloads the latest `next` release, verifies its checksum, and swaps the binary atomically with rollback on failure.

```sh
~/scripts/harness/update-harness.sh opencode2
```

Add a version after `opencode2` to install a specific one.

The update warning "automatic update skipped: installation method not found" is expected.
The binary is installed by the script, not a package manager, so auto-update cannot detect the installation method.

Paste an image into the prompt with Ctrl+V.
Screenshots copied in Windows arrive through WSLg as BMP data, and the TUI converts them to PNG automatically.

## Anti-slop lint skill

[anti-slop](https://github.com/dmmulroy/anti-slop) provides opinionated Oxlint rules that reject low-evidence TypeScript and JavaScript patterns.
Install the agent skill once per machine:

```sh
npx skills add dmmulroy/anti-slop --skill install-anti-slop
```

The command installs into `~/.agents/skills/install-anti-slop`, which OpenCode loads as a global skill source.
Restart the service so the skill appears:

```sh
opencode2 service restart
```

Then ask the agent to install anti-slop in a repository.
The skill vendors the plugin under `tools/oxlint/anti-slop/`, registers it in the lint config, installs matching `oxlint` packages, and enables every rule at `error`.
The copied rules are yours to adjust.
See the upstream [README](https://github.com/dmmulroy/anti-slop) for the rule list and the manual path.

## Service port (WSL2 mirrored networking)

The service port is set to 4096.
WSL2 mirrored networking blocks the Windows dynamic port range 49152-65535, so the port must stay below 49152.

```sh
opencode2 service set port 4096
```
