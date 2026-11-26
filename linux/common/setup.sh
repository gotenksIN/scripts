#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

bake_paths() {
    local file="$HOME/.zshrc"
    awk -v repo="${repo_dir}" '
        {
            while (s = index($0, "$HOME/scripts")) {
                $0 = substr($0, 1, s - 1) repo substr($0, s + 13)
            }
            print
        }
    ' "${file}" > "${file}.tmp"
    mv -- "${file}.tmp" "${file}"
}

add_distro_alias() {
    local distro="$1"
    local file="$HOME/.zshrc"
    local anchor="source \"${repo_dir}/linux/common/aliases\""
    local line="source \"${repo_dir}/linux/${distro}/alias\""

    if grep -qF "${line}" "${file}"; then
        return
    fi

    awk -v anchor="${anchor}" -v line="${line}" '
        { print }
        $0 == anchor { print line }
    ' "${file}" > "${file}.tmp"
    mv -- "${file}.tmp" "${file}"
}

setup_zsh() {
    local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
    local p10k_dir="$zsh_dir/custom/themes/powerlevel10k"

    if [[ ! -d "$zsh_dir" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    if [[ ! -d "$p10k_dir" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi

    if [[ "${SHELL:-}" != */zsh ]] && command -v zsh >/dev/null 2>&1; then
        local zsh_path
        zsh_path="$(command -v zsh)"
        if command -v chsh >/dev/null 2>&1; then
            chsh -s "$zsh_path" "$USER" 2>/dev/null || chsh -s "$zsh_path" 2>/dev/null || true
        elif command -v usermod >/dev/null 2>&1; then
            sudo usermod --shell "$zsh_path" "$USER" 2>/dev/null || true
        fi
    fi
}

copy_dotfiles() {
    local src name
    for src in "$repo_dir"/linux/common/.*; do
        [[ -e "${src}" ]] || continue
        name="$(basename "${src}")"
        [[ "${name}" == "." || "${name}" == ".." ]] && continue
        cp -a -- "${src}" "$HOME"/
    done
}

setup_opencode() {
    local opencode_dir="$repo_dir/opencode"

    export BUN_INSTALL="$HOME/.local"
    export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

    if ! command -v opencode >/dev/null 2>&1; then
        curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
    fi

    mkdir -p "$HOME/.config/opencode"
    mkdir -p "$HOME/.config/opencode/skills"
    ln -sf "$opencode_dir/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
    ln -sf "$opencode_dir/opencode.json" "$HOME/.config/opencode/opencode.json"
    for skill_dir in "$opencode_dir/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        skill_dir="${skill_dir%/}"
        ln -sfn "$skill_dir" "$HOME/.config/opencode/skills/$(basename "$skill_dir")"
    done
    [[ -e "$HOME/.config/opencode/cli.json" ]] || cp "$opencode_dir/cli.json" "$HOME/.config/opencode/cli.json"

    if ! command -v bun >/dev/null 2>&1; then
        curl -fsSL https://bun.sh/install | bash
    fi

    bun install -g skills@latest
    ln -sf "$HOME/.local/bin/bun" "$HOME/.local/bin/node"

    skills add mattpocock/skills --skill '*' --global --agent universal --yes
    skills add dmmulroy/anti-slop --skill install-anti-slop --global --agent universal --yes

    mkdir -p "$HOME/.config/topgrade.d"
    cat <<'EOF' >"$HOME/.config/topgrade.d/skills.toml"
[misc]
disable = ["github_cli_skills"]
EOF

    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        opencode service set port 4096
    fi

    opencode service start
    opencode models
    opencode service status
    opencode api get /api/info
}

setup_zsh
copy_dotfiles
bake_paths

read -r -e -p "Install OpenCode? [Y/n]: " input
if [[ ! "$input" =~ ^[Nn]$ ]]; then
    setup_opencode
fi

if (( $# > 0 )); then
    add_distro_alias "$1"
fi
