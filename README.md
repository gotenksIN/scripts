# Personal setup and system scripts

This repository contains configuration files, deployment scripts, and dotfiles for operating systems, containers, and tools.

## Repository structure

| Directory | Description |
| --- | --- |
| `linux/` | Installation, setup, dotfiles, and desktop configuration files for Linux. |
| `services/` | Docker Compose files and Home Assistant configurations for self-hosted services. |
| `opencode/` | Configuration files, agent rules, and an updater for OpenCode. |
| `windows/` | PowerShell scripts, Winget configurations, and chezmoi templates for Windows. |

## Subsystem details

### Linux (`linux/`)

Distribution-specific setup:

- `linux/arch/`: Arch Linux installation in three stages: `pre_chroot.sh` (archiso), `chroot.sh` (arch-chroot), and `user_setup.sh` (installed user). Also contains NVIDIA driver installation, KDE Plasma setup, Secure Boot configuration (`install_systemd-secureboot.sh`), and EFISTUB booting (`install_efistub.sh`).
- `linux/fedora/`: Fedora maintenance with automated system configuration via `setup.sh`, package removal using `debloat_fedora.sh`, NVIDIA driver setup, and Rawhide channel switching.
- `linux/ubuntu/`: Ubuntu system management with distro setup via `setup.sh`, package debloating, EFISTUB boot configuration, and GRUB removal.
- `linux/nixos/`: NixOS system configuration (`RyzenBox.nix`) and a script to switch system channels to unstable.

Desktop configurations:

- `linux/desktop/plasma/`: KWin script for push-style window tiling (`tile-pusher`), shortcut binding, and installation scripts.
- `linux/desktop/easyeffects/`: EasyEffects audio preset (`bass_boost.json`).

Common dotfiles:

- `linux/common/`: Shared environment settings and shell configurations:
  - Bootstrapper script `setup.sh` to install dotfiles across distributions.
  - Shell configuration files for Zsh (`.zshrc`, `.zprofile`, `.p10k.zsh`, `aliases`, `functions`).
  - Terminal and tool settings (`wezterm.lua`, `bottom.toml`, `.screenrc`).
  - SSH and Git configuration templates, and shared Git hooks.

### Self-hosted services (`services/`)

- `services/docker/`: Docker Compose files to deploy self-hosted applications:
  - **Home Assistant**: Home automation platform.
  - **Jellyfin**: Media server.
  - **qBittorrent**: Torrent client with optional Tailscale integration.
  - **RustDesk**: Self-hosted remote desktop server.
  - **SABnzbd**: Usenet downloader.
  - **WireGuard**: VPN service.
  - **OpenSpeedTest**: Network performance test tool.
  - **h5ai**: File indexer interface.
- `services/homeassistant/`: JSON configurations for smart home automation:
  - Custom dashboard layouts for television remotes and lighting controls.
  - Automation scripts for lighting based on time and sunset schedules.

### OpenCode (`opencode/`)

This directory contains configuration files, agent rules, and an updater for OpenCode v2.

- Configuration files: `opencode.json`, `opencode.jsonc`, and `cli.json`.
- Global agent rules: `AGENTS.md`.
- Binary updater: `update.sh`.

To link the OpenCode configuration files to your configuration directory:

```bash
mkdir -p ~/.config/opencode
ln -sf ~/scripts/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
ln -sf ~/scripts/opencode/opencode.json ~/.config/opencode/opencode.json
cp ~/scripts/opencode/cli.json ~/.config/opencode/cli.json
```

To update OpenCode, run the updater with an optional version:

```bash
~/scripts/opencode/update.sh [version]
```

### Windows (`windows/`)

Automation scripts for Windows and WSL:

- PowerShell setup scripts (`setup.ps1`, PowerShell profiles).
- Winget package configurations (`RyzenBox.json`, `GroundBox.json`).
- Registry adjustments and hardware acceleration fixes (`Fix-HEVC-AMF.ps1`).
- chezmoi templates for environment management.

## Getting started

To deploy the dotfiles and distribution-specific configurations on Linux:

```bash
bash ~/scripts/linux/common/setup.sh
```

The script detects your Linux distribution and applies the matching configuration files.

## License

This repository is licensed under the GNU General Public License v3.0 (`GPL-3.0`).
See the [LICENSE](LICENSE) file for full license terms.
