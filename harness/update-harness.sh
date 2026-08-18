#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

usage() {
  die "usage: $0 [opencode2|pi] [version]"
}

(( $# <= 2 )) || usage
if (( $# == 0 )); then
  "$0" opencode2
  "$0" pi
  exit 0
fi
target="$1"
requested_version="${2:-}"

need curl
need tar
need mktemp
need flock

case "$(uname -s)" in
  Linux) os="linux" ;;
  *) die "unsupported operating system: $(uname -s)" ;;
esac

case "$(uname -m)" in
  x86_64|amd64) arch="x64" ;;
  arm64|aarch64) arch="arm64" ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

case "$target" in
  opencode2)
    name="OpenCode v2"
    install_dir="${OPENCODE2_INSTALL_DIR:-$HOME/.opencode/bin}"
    executable="opencode2"
    package="cli-${os}-${arch}"
    metadata="$(curl -fsSL --retry 3 'https://registry.npmjs.org/@opencode-ai/cli/beta')"
    if [[ -n "$requested_version" ]]; then
      version="${requested_version#v}"
    else
      version="${metadata#*\"version\":\"}"
      version="${version%%\"*}"
      version="${version%\"}"
      [[ -n "$version" ]] || die "npm metadata did not contain the beta version"
    fi
    metadata_version="${metadata#*\"version\":\"}"
    metadata_version="${metadata_version%%\"*}"
    if [[ "$version" != "$metadata_version" ]]; then
      metadata="$(curl -fsSL --retry 3 \
        "https://registry.npmjs.org/@opencode-ai/cli/${version}")"
    fi
    metadata_version="${metadata#*\"version\":\"}"
    metadata_version="${metadata_version%%\"*}"
    [[ "$metadata_version" == "$version" ]] || die "npm metadata reported unexpected version"
    metadata="$(curl -fsSL --retry 3 \
      "https://registry.npmjs.org/@opencode-ai/${package}/${version}")"
    metadata_version="${metadata#*\"version\":\"}"
    metadata_version="${metadata_version%%\"*}"
    [[ "$metadata_version" == "$version" ]] || die "platform package metadata reported unexpected version"
    expected="${metadata#*\"shasum\":\"}"
    expected="${expected%%\"*}"
    [[ "$expected" =~ ^[0-9a-fA-F]{40}$ ]] || die "npm metadata did not contain a valid package checksum"
    asset="${package}-${version}.tgz"
    base_url="https://registry.npmjs.org/@opencode-ai/${package}/-"
    archive_prefix="package"
    binary_path="bin/opencode2"
    ;;
  pi)
    name="pi"
    install_dir="${PI_INSTALL_DIR:-$HOME/.local/lib/pi}"
    executable="pi"
    if [[ -n "$requested_version" ]]; then
      version="${requested_version#v}"
    else
      release_url="$(curl -fsSL --retry 3 -o /dev/null -w '%{url_effective}' \
        'https://github.com/earendil-works/pi/releases/latest')"
      tag="${release_url##*/}"
      [[ "$tag" == v* && "$tag" != v ]] || die "could not determine latest release"
      version="${tag#v}"
    fi
    asset="pi-${os}-${arch}.tar.gz"
    base_url="https://github.com/earendil-works/pi/releases/download/v${version}"
    archive_prefix="pi"
    binary_path="pi"
    ;;
  *) usage ;;
esac

[[ "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || die "invalid version: $version"

parent_dir="$(dirname "$install_dir")"
mkdir -p "$parent_dir"
exec 9>"$parent_dir/.${target}-update.lock"
flock -n 9 || die "another $target update is already running"

installed_binary="$install_dir/$executable"
if [[ -x "$installed_binary" ]]; then
  installed="$({ "$installed_binary" --version 2>/dev/null || true; } | head -n 1)"
  installed="${installed##* }"
  installed="${installed#v}"
  if [[ "$installed" == "$version" ]]; then
    printf '%s %s is already installed.\n' "$name" "$version"
    exit 0
  fi
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/${target}-update.XXXXXXXX")"
backup=""
deployment_path=""
cleanup() {
  status=$?
  if (( status != 0 )) && [[ -n "$backup" && -e "$backup" ]]; then
    rm -rf "$deployment_path"
    mv "$backup" "$deployment_path" || true
  fi
  rm -rf "$work_dir"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

printf 'Downloading %s %s (%s-%s)...\n' "$name" "$version" "$os" "$arch"
curl -fL --retry 3 -o "$work_dir/$asset" "$base_url/$asset"

if [[ "$target" == opencode2 ]]; then
  if command -v sha1sum >/dev/null 2>&1; then
    actual="$(sha1sum "$work_dir/$asset")"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 1 "$work_dir/$asset")"
  else
    die "required command not found: sha1sum or shasum"
  fi
  actual="${actual%% *}"
  [[ "${actual,,}" == "${expected,,}" ]] || die "checksum verification failed for $asset"
else
  curl -fL --retry 3 -o "$work_dir/SHA256SUMS" "$base_url/SHA256SUMS"
  expected="$(awk -v asset="$asset" '$2 == asset || $2 == "*" asset { print $1; exit }' \
    "$work_dir/SHA256SUMS")"
  [[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || die "release checksum for $asset was not found"
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$work_dir/$asset")"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$work_dir/$asset")"
  else
    die "required command not found: sha256sum or shasum"
  fi
  actual="${actual%% *}"
  [[ "${actual,,}" == "${expected,,}" ]] || die "checksum verification failed for $asset"
fi

while IFS= read -r entry; do
  entry="${entry#./}"
  entry="${entry%/}"
  [[ -n "$entry" && "$entry" != /* ]] || die "archive contains an unsafe path: $entry"
  case "/$entry/" in
    */../*|//*) die "archive contains an unsafe path: $entry" ;;
  esac
  [[ "$entry" == "$archive_prefix" || "$entry" == "$archive_prefix/"* ]] || \
    die "archive entry is outside $archive_prefix: $entry"
done < <(tar -tzf "$work_dir/$asset")

mkdir "$work_dir/unpacked"
tar -xzf "$work_dir/$asset" -C "$work_dir/unpacked" --strip-components=1 \
  --no-same-owner --no-same-permissions

new_binary="$work_dir/unpacked/$binary_path"
[[ -x "$new_binary" ]] || die "archive did not contain an executable $binary_path"
new_version="$({ "$new_binary" --version 2>/dev/null || true; } | head -n 1)"
new_version="${new_version##* }"
new_version="${new_version#v}"
[[ "$new_version" == "$version" ]] || \
  die "downloaded binary reported unexpected version: $new_version"

if [[ "$target" == opencode2 ]]; then
  deployment_path="$installed_binary"
  staged="$(mktemp "$install_dir/.${executable}-install.XXXXXXXX")"
  rm "$staged"
  mv "$new_binary" "$staged"
  if [[ -e "$deployment_path" ]]; then
    backup="$(mktemp "$install_dir/.${executable}-backup.XXXXXXXX")"
    rm "$backup"
    mv "$deployment_path" "$backup"
  fi
else
  deployment_path="$install_dir"
  staged="$work_dir/unpacked"
  backup="$(mktemp -d "$parent_dir/.${target}-backup.XXXXXXXX")"
  rmdir "$backup"
  if [[ -e "$deployment_path" ]]; then
    mv "$deployment_path" "$backup"
  else
    backup=""
  fi
fi

mv "$staged" "$deployment_path"
"$install_dir/$executable" --version >/dev/null 2>&1 || \
  die "installed $target failed to start"

if [[ -n "$backup" ]]; then
  rm -rf "$backup"
  backup=""
fi
printf 'Updated %s to %s in %s.\n' "$name" "$version" "$install_dir"
