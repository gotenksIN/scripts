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
| `update.sh` | Installer and updater for the `opencode` binary | Not installed |
| `README.md` | Setup and maintenance guide | Not installed |

## Setup on a fresh machine

Follow these steps to set up OpenCode on a fresh installation.

### 1. Clone the repository

```sh
git clone git@github.com:gotenksIN/scripts.git ~/scripts
```

### 2. Install OpenCode

Run the installer script to download and install the latest OpenCode binary into `~/.opencode/bin/`:

```sh
~/scripts/opencode/update.sh
```

### 3. Link the configuration files

Create the configuration directory, symlink the shared files, and copy the terminal settings:

```sh
mkdir -p ~/.config/opencode
ln -sf ~/scripts/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
ln -sf ~/scripts/opencode/opencode.json ~/.config/opencode/opencode.json
cp ~/scripts/opencode/cli.json ~/.config/opencode/cli.json
```

Copy `cli.json` instead of symlinking it.
OpenCode writes interactive settings changes directly to `cli.json`.

Do not copy `~/.config/opencode/service.json` between machines.
OpenCode generates `service.json` automatically and stores the local service password inside it.

### 4. Install global skills

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

### 5. Start OpenCode

Run OpenCode once to start the background service:

```sh
opencode
```

The service downloads and installs configured plugins in the background into `~/.cache/opencode/packages/`.

### 6. Configure WSL2 (optional)

If you run on WSL2, apply the configuration notes in the [WSL2 considerations](#wsl2-considerations) section.

### 7. Verify the installation

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

Run the update script to download and install the latest version:

```sh
~/scripts/opencode/update.sh
```

To install a specific version, provide the version number as an argument:

```sh
~/scripts/opencode/update.sh 1.2.3
```

The script verifies release checksums and replaces the binary atomically.
Ignore the warning "automatic update skipped: installation method not found".
The script manages the binary directly outside a system package manager.

### Applying configuration updates

Pull updates from Git and reload OpenCode:

```sh
cd ~/scripts
git pull
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
