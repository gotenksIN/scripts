# Pi setup

## Overview

This directory holds the Pi coding agent setup for this machine.
The files link into `~/.pi/agent/`, so this repo is the source of truth.

| File | Purpose | Installed as |
| --- | --- | --- |
| `settings.json` | Pi settings: extension package, theme, subagent package | Copied to `~/.pi/agent/settings.json` |
| `AGENTS.md` | Global agent rules for Pi | Symlinked to `~/.pi/agent/AGENTS.md` |
| `agents/` | Custom subagent definitions | Symlinked into `~/.pi/agent/agents/` |
| `README.md` | This guide | Not installed |

The extensions themselves live in the separate [pi-extensions](https://github.com/gotenksIN/pi-extensions) repository.
The `settings.json` package list installs that repository as a Pi extension package.

## Setup on a new machine

1. Install the `pi` binary with the update harness script.

   ```sh
   ~/scripts/harness/update-harness.sh pi
   ```

   The script downloads the latest release, verifies its checksum, and installs the binary to `~/.local/lib/pi/pi`.
   Make sure that directory is on your `PATH`.

2. Copy the settings file.

   ```sh
   cp ~/scripts/harness/pi/settings.json ~/.pi/agent/settings.json
   ```

   This replaces the destination settings file.
   Back up your current file first if it contains settings that you need to keep.

3. Link the global agent rules.

   ```sh
   ln -sfn ~/scripts/harness/pi/AGENTS.md ~/.pi/agent/AGENTS.md
   ```

4. Link the custom subagent definitions.

   ```sh
   mkdir -p ~/.pi/agent/agents
   ln -sfn ~/scripts/harness/pi/agents/*.md ~/.pi/agent/agents/
   ```

   These commands preserve custom agents with other names and replace agents with the same filenames.
   After setup, `/agents` lists the tracked definitions as global agents.
   Agent names are case-insensitive, so `explore` resolves to `Explore.md`.

5. Install Bun if missing, because Pi needs a JavaScript package manager for Git packages.
   The standalone Pi binary does not include Node.js or npm.
   Skip this step if `bun` is already installed and on your `PATH`.

   ```sh
   if ! command -v bun >/dev/null 2>&1; then
     (
       set -e

       work="$(mktemp -d "${TMPDIR:-/tmp}/bun-install.XXXXXXXX")"
       mkdir -p "$HOME/.local/bin"
       cd "$work"

       gh release download \
         --repo oven-sh/bun \
         --pattern 'bun-linux-x64.zip' \
         --pattern 'SHASUMS256.txt'

       sha256sum --check --ignore-missing SHASUMS256.txt
       7z x bun-linux-x64.zip

       /usr/bin/install -Dm755 \
         "$work/bun-linux-x64/bun" \
         "$HOME/.local/bin/bun"
       ln -sfn "$HOME/.local/bin/bun" "$HOME/.local/bin/bunx"

       "$HOME/.local/bin/bun" --version
       "$HOME/.local/bin/bunx" --version
       rm -rf "$work"
     )
   fi
   ```

6. Resolve and install extension packages with Bun present.

   ```sh
   pi update --extensions
   ```

   If `pi-subagents` failed to install its dependencies before Bun was available, run its production build directly as a fallback:

   ```sh
   cd ~/.pi/agent/git/github.com/tintinweb/pi-subagents
   bun install --production --ignore-scripts --no-save
   ```

7. Restart Pi or reload its extensions:

   ```text
   /reload
   ```

Pi packages run with your user permissions.
Review package source before you install it.

## Bubblewrap sandbox launcher installation

The `bwrap-sandbox` extension needs two privileged host artifacts:

- `/usr/local/bin/bwrap-hardened`, the root-owned launcher binary (mode `0755`)
- `/etc/sandbox-seccomp.bpf`, the Seccomp BPF profile (mode `0644`)

Both are built from source with a Slim LLVM toolchain downloaded from kernel.org.
The build runs as your normal user.
Only the final copy needs sudo.

This guide works for any agent: follow the steps in order and replace nothing else.

### Prerequisites

- Linux kernel 5.13 or newer with Landlock and Seccomp BPF enabled.
- `x86_64` architecture.
- `sudo`, `curl`, and `7z` available.
- Bubblewrap, the libc development headers, and the gcc runtime files.
  The Slim LLVM toolchain does not ship libc headers, crt objects, or libgcc, so the distribution must provide them:

  ```bash
  # Debian or Ubuntu
  sudo apt update
  sudo apt install bubblewrap libc6-dev libgcc-15-dev
  ```

  The `libgcc-15-dev` version number follows the gcc version of the release.
  Use the version apt offers if `15` is not available.

  ```bash
  # Fedora or RHEL
  sudo dnf install bubblewrap glibc-devel gcc

  # Arch or Manjaro
  sudo pacman -S bubblewrap glibc gcc
  ```

- A working Pi installation with the extension packages installed.
  After setting up Bun as the package manager, run:

  ```sh
  pi update --extensions
  ```

  This installs the pi-extensions package, which contains the launcher source, at:

  ```text
  ~/.pi/agent/git/github.com/gotenksIN/pi-extensions
  ```

  No separate checkout is needed.
  See [Setup on a new machine](#setup-on-a-new-machine) and [Updating](#updating).

### 1. Download the Slim LLVM toolchain

The toolchains at https://www.kernel.org/pub/tools/llvm/files/ are PGO-built and minimal.
This step downloads the latest stable `x86_64` toolchain:

```sh
work="$(mktemp -d "${TMPDIR:-/tmp}/bwrap-llvm.XXXXXXXX")"
cd "$work"

curl -fsSL https://www.kernel.org/pub/tools/llvm/files/ -o files.html
latest="$(grep -oE 'llvm-[0-9]+\.[0-9]+\.[0-9]+-x86_64\.tar\.xz' files.html \
  | sort -V | tail -n 1)"
curl -fLO "https://www.kernel.org/pub/tools/llvm/files/$latest"

7z x "$latest"
7z x "${latest%.xz}"
```

The extraction produces a directory named `llvm-<version>-x86_64` with `clang` and `ld.lld` under `bin/`.

The toolchains need these runtime libraries:

- Arch: `gcc-libs glibc icu libxml2 xz zlib zstd`
- Debian: `libc6 libgcc-s1 libicu67 liblzma5 libstdc++6 libxml2 libzstd1 zlib1g`
- Fedora: `glibc libgcc libstdc++ libxml2 libzstd xz-libs zlib`

### 2. Build the launcher and Seccomp profile

The build runs from the installed extension package and writes only inside the temporary directory from step 1.

```sh
pkg_root="$HOME/.pi/agent/git/github.com/gotenksIN/pi-extensions"
llvm_dir="$(ls -d "$work"/llvm-*-x86_64 | sort -V | tail -n 1)"
build_dir="$work/build"
mkdir -p "$build_dir"

"$llvm_dir/bin/clang" -O3 -flto=full -fuse-ld=lld -fvisibility=hidden \
  -fstack-clash-protection -fstack-protector-strong -D_FORTIFY_SOURCE=3 \
  -ftrivial-auto-var-init=pattern -fPIE -pie -Wl,-z,relro,-z,now \
  -Wl,-z,noexecstack -Wall -Wextra -Werror \
  -x c "$pkg_root/extensions/bwrap-sandbox/launcher/seccomp-profile.bpf" \
  -o "$build_dir/seccomp-profile-generator"
"$build_dir/seccomp-profile-generator" > "$build_dir/sandbox-seccomp.bpf"
test -s "$build_dir/sandbox-seccomp.bpf"

"$llvm_dir/bin/clang" -O3 -flto=full -fuse-ld=lld -fvisibility=hidden \
  -fstack-clash-protection -fstack-protector-strong -D_FORTIFY_SOURCE=3 \
  -ftrivial-auto-var-init=pattern -fPIE -pie -Wl,-z,relro,-z,now \
  -Wl,-z,noexecstack -Wall -Wextra -Werror \
  -fsanitize=cfi -fsanitize=shadow-call-stack \
  "$pkg_root/extensions/bwrap-sandbox/launcher/bwrap-hardened.c" \
  -o "$build_dir/bwrap-hardened"

( cd "$build_dir" && sha256sum bwrap-hardened sandbox-seccomp.bpf > SHA256SUMS )
```

Use the extracted Slim LLVM `clang`, never a system `cc` or `gcc`.

On x86-64, `-fsanitize=shadow-call-stack` does not provide the separate AArch64 or RISC-V shadow stack mechanism and can have no extra effect.

### 3. Copy the artifacts with sudo

The launcher install script only copies already-built artifacts.
It expects them in the directory it runs from, or takes the build directory as its only argument:

```sh
cd "$build_dir"
sudo bash "$pkg_root/extensions/bwrap-sandbox/launcher/install.sh"
```

Or, without changing directory:

```sh
sudo bash "$pkg_root/extensions/bwrap-sandbox/launcher/install.sh" "$build_dir"
```

The script verifies the artifacts, stages them under `/root`, and installs:

- `/usr/local/bin/bwrap-hardened` owned by `root:root` with mode `0755`
- `/etc/sandbox-seccomp.bpf` owned by `root:root` with mode `0644`

It prints both SHA-256 digests at the end.

### 4. Check and update the pinned digests

Compare the built digests with the pins:

```sh
sha256sum "$build_dir/bwrap-hardened" "$build_dir/sandbox-seccomp.bpf"
grep -n 'SHA256' "$pkg_root/extensions/bwrap-sandbox/runtime-contract.ts"
```

If a built digest differs from its pin, update the matching constant in `runtime-contract.ts`.
The extension fails closed at startup until the pinned digests match the installed files.

### 5. Verify

```sh
stat -c "%U:%G %a" /usr/local/bin/bwrap-hardened
stat -c "%U:%G %a" /etc/sandbox-seccomp.bpf
test ! -u /usr/local/bin/bwrap-hardened && echo "VERIFIED: Not setuid"
sha256sum /usr/local/bin/bwrap-hardened /usr/bin/bwrap /etc/sandbox-seccomp.bpf
```

Expected ownership output:

```text
root:root 755
root:root 644
```

### 6. Clean up

Delete the temporary directory that holds the toolchain and the built artifacts:

```sh
rm -rf "$work"
```

## Updating

Update the binary with the harness script:

```sh
~/scripts/harness/update-harness.sh pi
```

Update the installed extension packages from inside Pi:

```bash
pi update --extensions
```

## Extensions

Each extension has two documents in the pi-extensions repository:

- `README.md` is for users.
  It explains purpose, installation, configuration, commands, tools, and visible behavior.
- `AGENTS.md` is for coding agents.
  It explains module ownership, implementation details, invariants, and change checks.

- [`bwrap-sandbox`](https://github.com/gotenksIN/pi-extensions/tree/main/extensions/bwrap-sandbox) provides a Linux Bubblewrap boundary and approval gate for Bash and selected Pi file tools.
- [`delete-session`](https://github.com/gotenksIN/pi-extensions/tree/main/extensions/delete-session) deletes the current session file after confirmation and starts a new session.
- [`keybinding-shortcuts`](https://github.com/gotenksIN/pi-extensions/tree/main/extensions/keybinding-shortcuts) adds OpenCode-style command and word-deletion shortcuts to the Pi TUI editor.
- [`websearch`](https://github.com/gotenksIN/pi-extensions/tree/main/extensions/websearch) provides provider-native grounded web search with citations and ordered fallback.

Read the matching `AGENTS.md` before you change an extension.

### Bubblewrap sandbox

`bwrap-sandbox` is Linux-only.
See [Bubblewrap sandbox launcher installation](#bubblewrap-sandbox-launcher-installation) for the full setup.
