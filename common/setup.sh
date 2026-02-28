#!/usr/bin/env bash

set -euo pipefail

add_line() {
    local file="$1"
    local line="$2"

    [ -n "$(tail -c 1 "${file}")" ] && echo >> "${file}"
    grep -q "${line}" "${file}" || echo "${line}" >> "${file}"
}

copy_dotfiles() {
    local src name
    for src in ~/scripts/common/.*; do
        [[ -e "${src}" ]] || continue
        name="$(basename "${src}")"
        [[ "${name}" == "." || "${name}" == ".." ]] && continue
        cp -a -- "${src}" ~/
    done
}

if command -v apt >/dev/null 2>&1; then
    echo "Debian/Ubuntu based distro detected"
    bash ~/scripts/ubuntu/setup.sh
    copy_dotfiles
    add_line ~/.zshrc "source ~/scripts/ubuntu/alias"
elif command -v pacman >/dev/null 2>&1; then
    echo "Arch based distro detected"
    bash ~/scripts/arch/setup.sh
    copy_dotfiles
    add_line ~/.zshrc "source ~/scripts/arch/alias"
elif command -v dnf >/dev/null 2>&1; then
    echo "Fedora based distro detected"
    bash ~/scripts/fedora/setup.sh
    copy_dotfiles
    add_line ~/.zshrc "source ~/scripts/fedora/alias"
fi
