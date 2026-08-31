# Personal setup and system scripts

This repository contains configuration files, deployment scripts, and dotfiles for operating systems, containers, and tools.

## Repository structure

| Directory | Description |
| --- | --- |
| `arch/` | Installation and configuration scripts for Arch Linux. |
| `common/` | Shared shell configurations, dotfiles, and system setup scripts. |
| `docker/` | Docker Compose files for self-hosted services. |
| `fedora/` | Setup, debloat, and management scripts for Fedora Linux. |
| `homeassistant/` | Automation scripts and dashboard configurations for Home Assistant. |
| `nixos/` | NixOS system configuration files and update scripts. |
| `harness/` | Configuration files, agent rules, and install scripts for AI agent harnesses (OpenCode, Pi). |
| `plasma/` | KDE Plasma window management scripts and tiling tools. |
| `ubuntu/` | Setup, debloat, and bootloader scripts for Ubuntu Linux. |
| `windows/` | PowerShell scripts, Winget configurations, and chezmoi templates for Windows. |

## Subsystem details

### Arch Linux (`arch/`)
Scripts in this folder handle Arch Linux setup:
- System installation using `pre_chroot.sh`, `chroot.sh`, and `user_setup.sh`.
- Secure Boot configuration with `install_systemd-secureboot.sh`.
- Kernel booting setup with `install_efistub.sh`.
- NVIDIA driver installation and KDE Plasma desktop setup.

### Common dotfiles (`common/`)
Shared environment settings and shell configurations:
- Bootstrapper script `setup.sh` to install dotfiles across distributions.
- Shell configuration files for Zsh (`.zshrc`, `.zprofile`, `.p10k.zsh`, `aliases`, `functions`).
- Terminal and tool settings (`wezterm.lua`, `bottom.toml`, `.screenrc`).
- SSH and Git configuration templates.

### Docker services (`docker/`)
Docker Compose files to deploy self-hosted applications:
- **Home Assistant**: Home automation platform.
- **Jellyfin**: Media server.
- **qBittorrent**: Torrent client with optional Tailscale integration.
- **RustDesk**: Self-hosted remote desktop server.
- **SABnzbd**: Usenet downloader.
- **WireGuard**: VPN service.
- **OpenSpeedTest**: Network performance test tool.
- **h5ai**: File indexer interface.

### Fedora (`fedora/`)
Scripts for Fedora maintenance:
- Automated system configuration via `setup.sh`.
- Package removal using `debloat_fedora.sh`.
- NVIDIA driver setup and Rawhide channel switching.

### Home Assistant (`homeassistant/`)
JSON configurations for smart home automation:
- Custom dashboard layouts for television remotes and lighting controls.
- Automation scripts for lighting based on time and sunset schedules.

### NixOS (`nixos/`)
System configuration for NixOS builds:
- Machine configuration file `RyzenBox.nix`.
- Script to switch system channels to unstable.

### Agent harnesses (`harness/`)
Configuration files, agent rules, and installation scripts for AI coding harnesses:
- **OpenCode (`harness/opencode/`)**: Configuration files (`opencode.json`, `opencode.jsonc`, `cli.json`) and agent rules (`AGENTS.md`) for OpenCode v2.
- **Pi (`harness/pi/`)**: Settings (`settings.json`), custom subagents (`agents/`), keybindings (`keybindings.json`), and agent rules (`AGENTS.md`) for Pi.
- **Harness updater (`harness/update-harness.sh`)**: Script to download and update `opencode2` and `pi` binaries.

To link the OpenCode configuration files to your configuration directory:

```bash
mkdir -p ~/.config/opencode
ln -sf ~/scripts/harness/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
ln -sf ~/scripts/harness/opencode/opencode.json ~/.config/opencode/opencode.json
cp ~/scripts/harness/opencode/cli.json ~/.config/opencode/cli.json
```

### KDE Plasma (`plasma/`)
Window management extensions:
- `tile-pusher`: KWin script for push-style window tiling.
- Shortcut binding and installation scripts.

### Ubuntu (`ubuntu/`)
Ubuntu system management scripts:
- Distro setup via `setup.sh`.
- System package debloating and GRUB removal.
- EFISTUB boot configuration.

### Windows (`windows/`)
Automation scripts for Windows and WSL:
- PowerShell setup scripts (`setup.ps1`, PowerShell profiles).
- Winget package configurations (`RyzenBox.json`, `GroundBox.json`).
- Registry adjustments and hardware acceleration fixes (`Fix-HEVC-AMF.ps1`).
- chezmoi templates for environment management.

## Getting started

To deploy the common dotfiles and distribution-specific configurations on Linux:

```bash
bash ~/scripts/common/setup.sh
```

The script detects your Linux distribution and applies the matching configuration files.

## License

This repository is licensed under the GNU General Public License v3.0 (`GPL-3.0`).
See the [LICENSE](LICENSE) file for full license terms.
