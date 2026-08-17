# Pi setup

## Overview

This directory holds the Pi coding agent setup for this machine.
The files link into `~/.pi/agent/`, so this repo is the source of truth.

| File | Purpose | Installed as |
| --- | --- | --- |
| `settings.json` | Pi settings: extension package, theme, subagent package | Copied to `~/.pi/agent/settings.json` |
| `keybindings.json` | Removes default `ctrl+p` bindings that conflict with the keybinding extension | Copied to `~/.pi/agent/keybindings.json` |
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
   mkdir -p ~/.pi/agent
   cp ~/scripts/harness/pi/settings.json ~/.pi/agent/settings.json
   ```

   This replaces the destination settings file.
   Back up your current file first if it contains settings that you need to keep.

3. Copy the keybindings file.

   ```sh
   cp ~/scripts/harness/pi/keybindings.json ~/.pi/agent/keybindings.json
   ```

   This file removes the default `ctrl+p` bindings that conflict with the keybinding extension.
   Skip this step if you do not use `keybinding-shortcuts`.

4. Link the global agent rules.

   ```sh
   ln -sfn ~/scripts/harness/pi/AGENTS.md ~/.pi/agent/AGENTS.md
   ```

5. Link the custom subagent definitions.

   ```sh
   mkdir -p ~/.pi/agent/agents
   ln -sfn ~/scripts/harness/pi/agents/*.md ~/.pi/agent/agents/
   ```

   These commands preserve custom agents with other names and replace agents with the same filenames.
   After setup, `/agents` lists the tracked definitions as global agents.
   Agent names are case-insensitive, so `explore` resolves to `Explore.md`.

6. Install Bun if missing, because Pi needs a JavaScript package manager for Git packages.
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

7. Install [Matt Pocock's skills](https://github.com/mattpocock/skills) globally for Pi.

   ```sh
   bunx skills@latest add mattpocock/skills --skill '*' --global --agent pi --yes
   ```

   The installer keeps one copy in `~/.agents/skills/` and links it into Pi's global skill directory.

8. Resolve and install extension packages with Bun present.

   ```sh
   pi update --extensions
   ```

   If `pi-subagents` failed to install its dependencies before Bun was available, run its production build directly as a fallback:

   ```sh
   cd ~/.pi/agent/git/github.com/tintinweb/pi-subagents
   bun install --production --ignore-scripts --no-save
   ```

9. Restart Pi or reload its extensions:

   ```text
   /reload
   ```

10. Log in to a provider before your first prompt.
   Pi needs authenticated provider credentials for every model call, including the sandbox classifier and web search.

   Start Pi and run `/login`, then select a provider:

   ```text
   /login
   ```

   The command supports OAuth subscriptions and API keys.
   Credentials are stored in `~/.pi/agent/auth.json`.
   For API-key providers you can also export the matching environment variable instead.
   See the provider reference in `~/.local/lib/pi/docs/providers.md` for provider names, OAuth steps, and environment variable names.

   Verify the provider is ready before you continue:

   ```sh
   pi auth check --provider <provider-name>
   ```

   The check must print `ready`.
   Example: `pi auth check --provider openai`.

11. In each repository, run the setup skill once and answer its prompts.

    ```text
    /setup-matt-pocock-skills
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
  -x c "$pkg_root/bwrap-sandbox/launcher/seccomp-profile.bpf" \
  -o "$build_dir/seccomp-profile-generator"
"$build_dir/seccomp-profile-generator" > "$build_dir/sandbox-seccomp.bpf"
test -s "$build_dir/sandbox-seccomp.bpf"

"$llvm_dir/bin/clang" -O3 -flto=full -fuse-ld=lld -fvisibility=hidden \
  -fstack-clash-protection -fstack-protector-strong -D_FORTIFY_SOURCE=3 \
  -ftrivial-auto-var-init=pattern -fPIE -pie -Wl,-z,relro,-z,now \
  -Wl,-z,noexecstack -Wall -Wextra -Werror \
  -fsanitize=cfi -fsanitize=shadow-call-stack \
  "$pkg_root/bwrap-sandbox/launcher/bwrap-hardened.c" \
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
sudo bash "$pkg_root/bwrap-sandbox/launcher/install.sh"
```

Or, without changing directory:

```sh
sudo bash "$pkg_root/bwrap-sandbox/launcher/install.sh" "$build_dir"
```

The script verifies the artifacts, stages them under `/root`, and installs:

- `/usr/local/bin/bwrap-hardened` owned by `root:root` with mode `0755`
- `/etc/sandbox-seccomp.bpf` owned by `root:root` with mode `0644`

It prints both SHA-256 digests at the end.

### 4. Check and update the pinned digests

Compare the built digests with the pins:

```sh
sha256sum "$build_dir/bwrap-hardened" "$build_dir/sandbox-seccomp.bpf"
grep -n 'SHA256' "$pkg_root/bwrap-sandbox/runtime/runtime-contract.ts"
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

## Anti-slop lint skill

[anti-slop](https://github.com/dmmulroy/anti-slop) provides opinionated Oxlint rules that reject low-evidence TypeScript and JavaScript patterns.
Install the agent skill once per machine:

```sh
bunx skills@latest add dmmulroy/anti-slop --skill install-anti-slop --global --agent pi --yes
```

The command installs into `~/.agents/skills/install-anti-slop`, which Pi loads as a global skill source.
Restart Pi so the skill appears.

Then ask Pi to install anti-slop in a repository.
The skill vendors the plugin under `tools/oxlint/anti-slop/`, registers it in the lint config, installs matching `oxlint` packages, and enables every rule at `error`.
The copied rules are yours to adjust.
See the upstream [README](https://github.com/dmmulroy/anti-slop) for the rule list and the manual path.

## Extensions

Each extension has two documents in the pi-extensions repository:

- `README.md` is for users.
  It explains purpose, installation, configuration, commands, tools, and visible behavior.
- `AGENTS.md` is for coding agents.
  It explains module ownership, implementation details, invariants, and change checks.

- [`bwrap-sandbox`](https://github.com/gotenksIN/pi-extensions/tree/main/bwrap-sandbox) provides a Linux Bubblewrap boundary and approval gate for Bash and selected Pi file tools.
- [`delete-session`](https://github.com/gotenksIN/pi-extensions/tree/main/delete-session) deletes the current session file after confirmation and starts a new session.
- [`keybinding-shortcuts`](https://github.com/gotenksIN/pi-extensions/tree/main/keybinding-shortcuts) adds OpenCode-style command and word-deletion shortcuts to the Pi TUI editor.
- [`websearch`](https://github.com/gotenksIN/pi-extensions/tree/main/websearch) provides provider-native grounded web search with citations and ordered fallback.

Read the matching `AGENTS.md` before you change an extension.

### Bubblewrap sandbox

`bwrap-sandbox` is Linux-only.
It requires Bubblewrap and the `bwrap-hardened` launcher.
See [Bubblewrap sandbox launcher installation](#bubblewrap-sandbox-launcher-installation) for the full setup.

The extension starts from a read-only host root.
It uses deterministic path and direct secret checks, Bubblewrap mounts, user-approved session grants, exact one-shot write paths, and one classifier reviewer for model-generated Bash.
The default reviewer is `openai/gpt-5.6-luna` with `low` reasoning.
The reviewer can use bounded user-role instructions to authorize matching, narrowly scoped Bash mutations and one deterministically validated atomic write-path set for one exact future Bash call.
It treats deterministic reads from fixed public remote resources as routine when the request cannot include local, project, environment, credential, secret, proprietary, prior-output, or dynamic data.
A missing or failed reviewer does not use model fallback and sends the exact action to human review.
Bubblewrap is the primary security boundary.
Read its [user guide](https://github.com/gotenksIN/pi-extensions/blob/main/bwrap-sandbox/README.md) before you configure it.

The extension's global configuration is:

```text
~/.pi/agent/extensions/sandbox.json
```

The default classifier configuration is equivalent to:

```json
{
  "classifier": {
    "reviewer": {
      "provider": "openai",
      "model": "gpt-5.6-luna",
      "reasoning": "low"
    },
    "timeoutMs": 30000,
    "maxRetries": 1
  }
}
```

Only global configuration can replace `classifier.reviewer`.
If the model, provider, authentication, or provider call is unavailable, the extension uses human review and tells the user that they can configure `classifier.reviewer` globally.
It does not use a fallback model.

Trusted project configuration is:

```text
.pi/sandbox.json
```

The extension registers the `/sandbox` command and the `sandbox_access` tool.
`/sandbox` shows the current sandbox status.
`/sandbox off` disables the sandbox for the current session only.
It turns off the OS boundary, the tri-tier authorization, and the direct host file-tool checks for the rest of the session, without a confirmation prompt.
`/sandbox on` re-enables the sandbox and re-runs full initialization.
It is rejected when `--no-sandbox` or configuration disabled the sandbox.
The toggles do not persist across sessions.
These surfaces and their safety rules are documented in the extension guide.

Starting Pi with `--no-sandbox` disables the sandbox for the parent and all subagent sessions in that Pi process.
A child cannot restore it silently.

### Web search

`websearch` registers `websearch_cited`.
It uses Pi's model registry and authentication.
It does not need separate API keys.
Its global and project configuration files are:

```text
~/.pi/agent/extensions/websearch.json
.pi/websearch.json
```

Read the [websearch user guide](https://github.com/gotenksIN/pi-extensions/blob/main/websearch/README.md) for model fallback, tool parameters, provider behavior, and errors.

### Delete session

`delete-session` registers `/delete`.
The command asks for confirmation, waits for Pi to become idle, removes the current session file, and starts a new session.
It does nothing for an ephemeral session.

Read the [delete-session user guide](https://github.com/gotenksIN/pi-extensions/blob/main/delete-session/README.md) for use.

### Keybinding shortcuts

`keybinding-shortcuts` replaces the editor component only in TUI mode.
It maps `ctrl+p` to Pi's slash-command menu, and maps `ctrl+backspace` and `ctrl+delete` to word deletion.

The extension needs the conflicting default `ctrl+p` actions removed from `~/.pi/agent/keybindings.json`.
The tracked `keybindings.json` in this directory removes them.
Read the [keybinding user guide](https://github.com/gotenksIN/pi-extensions/blob/main/keybinding-shortcuts/README.md) for details.
