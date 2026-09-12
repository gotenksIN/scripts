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

copy_dotfiles() {
    local src name
    for src in "$repo_dir"/linux/common/.*; do
        [[ -e "${src}" ]] || continue
        name="$(basename "${src}")"
        [[ "${name}" == "." || "${name}" == ".." ]] && continue
        cp -a -- "${src}" "$HOME"/
    done
}

copy_dotfiles
bake_paths

if (( $# > 0 )); then
    add_distro_alias "$1"
fi

git config --global core.hooksPath "$repo_dir/linux/common/git-hooks"
