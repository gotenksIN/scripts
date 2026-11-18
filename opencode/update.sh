#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

(( $# <= 1 )) || die "usage: $0 [version]"
need curl
need sed
need flock

[[ "$(uname -s)" == Linux ]] || die "unsupported operating system: $(uname -s)"

install_dir="$HOME/.opencode/bin"
mkdir -p "$(dirname "$install_dir")"
exec 9>"$(dirname "$install_dir")/.opencode-update.lock"
flock -n 9 || die "another OpenCode update is already running"

if [[ -n "${1:-}" ]]; then
  version="${1#v}"
else
  version="$(curl -fsSL --retry 3 'https://opencode.ai/update/api/dev/cli/npm' |
    sed -n 's/.*"version":"\([^"]*\)".*/\1/p')"
fi
[[ "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || die "invalid version: $version"

if [[ -x "$install_dir/opencode" ]]; then
  installed="$({ "$install_dir/opencode" --version 2>/dev/null || true; } | head -n 1)"
  installed="${installed##* }"
  if [[ "${installed#v}" == "$version" ]]; then
    printf 'OpenCode %s is already installed.\n' "$version"
    exit 0
  fi
fi

curl -fsSL --retry 3 'https://opencode.ai/v2/install' |
  bash -s -- --version "$version" --no-modify-path

printf 'If the OpenCode service is running, run: opencode service restart\n'
