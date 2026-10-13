# OpenCode setup

## Overview

This directory stores the global OpenCode v2 configuration for this machine.
Files in `~/.config/opencode/` link to or copy from this repository.
Keep your API keys and credentials local; do not commit them to the repository.

| File | Purpose | Installed as |
| --- | --- | --- |
| `AGENTS.md` | Global agent instructions and workflow rules | Symlink at `~/.config/opencode/AGENTS.md` |
| `opencode.json` | Global configuration: plugins, subagents, and web search | Symlink at `~/.config/opencode/opencode.json` |
| `opencode.jsonc` | Provider configuration template with placeholders | Not installed |
| `cli.json` | TUI settings: themes, keybindings, and diff displays | Copied to `~/.config/opencode/cli.json` |
| `README.md` | Setup and maintenance guide | Not installed |

## Setup on a fresh machine

Follow these steps to set up OpenCode on a fresh installation.

### 1. Install OpenCode

Run the installer to download and install the OpenCode binary into `~/.opencode/bin/`:

```sh
curl -fsSL https://opencode.ai/install | bash
```

### 2. Link the configuration files

Create the configuration directory, symlink the shared files, and copy the terminal settings:

```sh
mkdir -p ~/.config/opencode
ln -sf ~/scripts/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
ln -sf ~/scripts/opencode/opencode.json ~/.config/opencode/opencode.json
cp ~/scripts/opencode/cli.json ~/.config/opencode/cli.json
```

If `~/scripts` is not present, ignore the symlink step and download the configuration files directly from Git.

Copy `cli.json` instead of symlinking it.
OpenCode writes interactive settings changes directly to `cli.json`.

Do not copy `~/.config/opencode/service.json` between machines.
OpenCode generates `service.json` automatically and stores the local service password inside it.

### 3. Install global skills

OpenCode loads global agent skills from `~/.agents/skills/`.
Install Bun if you do not have it:

```sh
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

The Bun installer provides only the `bun` binary.
Always run `bun x` instead of `bunx`.

Install Matt Pocock's skills and the anti-slop linting skill:

```sh
bun x skills@latest add mattpocock/skills --skill '*' --global --agent opencode --yes
bun x skills@latest add dmmulroy/anti-slop --skill install-anti-slop --global --agent opencode --yes
```

The `--global` flag installs skills into `~/.agents/skills/`.
The `--agent opencode` flag targets OpenCode and avoids writing copies to other agent directories.
OpenCode watches `~/.agents/skills/` and detects added skills automatically.

### 4. Start OpenCode

Run OpenCode once to start the background service:

```sh
opencode
```

The service downloads and installs configured plugins in the background into `~/.cache/opencode/packages/`.

### 5. Configure WSL2 (optional)

If you run on WSL2, apply the configuration notes in the [WSL2 considerations](#wsl2-considerations) section.

### 6. Verify the installation

Verify that OpenCode and its services run correctly:

```sh
opencode models
opencode service status
opencode api get /api/health
```

Confirm that the subagents `coder`, `reasoner`, `explore`, and `general` appear in the TUI.
Confirm that `/setup-matt-pocock-skills` appears in the commands list.

## Skills

### Matt Pocock's skills

Run the setup skill once in each repository:

```text
/setup-matt-pocock-skills
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
WSLg passes images copied in Windows as BMP format.
The TUI converts them to PNG automatically.

### Service port for mirrored networking

WSL2 mirrored networking reserves the dynamic port range 49152-65535 on Windows.
Keep the OpenCode service port below 49152:

```sh
opencode service set port 4096
```

### Topgrade execution

Topgrade on Windows updates WSL distributions through non-interactive login shells using `bash -lc`.
Non-interactive Bash shells read `~/.profile` but ignore `~/.zshrc`.
Standard `~/.bashrc` files also return early when invoked non-interactively.
If you define `PATH` only in `~/.zshrc`, Topgrade cannot find `opencode` and skips the upgrade step.

Add the binary path to `~/.profile` so non-interactive shells find OpenCode:

```sh
echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.profile
```
