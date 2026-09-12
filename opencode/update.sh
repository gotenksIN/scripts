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
  die "usage: $0 [version]"
}

(( $# <= 1 )) || usage
requested_version="${1:-}"

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
  *) die "unsupported architecture: $(uname -m)" ;;
esac

name="OpenCode v2"
install_dir="${OPENCODE2_INSTALL_DIR:-$HOME/.opencode/bin}"
executable="opencode2"
package="cli-${os}-${arch}"
if [[ -n "$requested_version" ]]; then
  version="${requested_version#v}"
else
  metadata="$(curl -fsSL --retry 3 \
    'https://opencode.ai/update/api/dev/cli/npm')"
  version="${metadata#*\"version\":\"}"
  version="${version%%\"*}"
fi
[[ "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || die "invalid version: $version"

metadata="$(curl -sSL --retry 3 -w $'\n%{http_code}' \
  "https://registry.npmjs.org/@opencode%2f${package}/${version}")" || \
  die "failed to fetch platform package metadata"
http_status="${metadata##*$'\n'}"
metadata="${metadata%$'\n'*}"
[[ "$http_status" == 200 ]] || \
  die "version $version is not available for $os-$arch"

metadata_version="${metadata#*\"version\":\"}"
metadata_version="${metadata_version%%\"*}"
[[ "$metadata_version" == "$version" ]] || die "platform package metadata reported unexpected version"
expected="${metadata#*\"shasum\":\"}"
expected="${expected%%\"*}"
[[ "$expected" =~ ^[0-9a-fA-F]{40}$ ]] || die "npm metadata did not contain a valid package checksum"
asset="${package}-${version}.tgz"
base_url="https://registry.npmjs.org/@opencode/${package}/-"

parent_dir="$(dirname "$install_dir")"
mkdir -p "$parent_dir"
exec 9>"$parent_dir/.opencode2-update.lock"
flock -n 9 || die "another OpenCode update is already running"
mkdir -p "$install_dir"

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

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/opencode2-update.XXXXXXXX")"
backup=""
cleanup() {
  status=$?
  if (( status != 0 )) && [[ -n "$backup" && -e "$backup" ]]; then
    rm -f "$installed_binary"
    mv "$backup" "$installed_binary" || true
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

if command -v sha1sum >/dev/null 2>&1; then
  actual="$(sha1sum "$work_dir/$asset")"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 1 "$work_dir/$asset")"
else
  die "required command not found: sha1sum or shasum"
fi
actual="${actual%% *}"
[[ "${actual,,}" == "${expected,,}" ]] || die "checksum verification failed for $asset"

while IFS= read -r entry; do
  entry="${entry#./}"
  entry="${entry%/}"
  [[ -n "$entry" && "$entry" != /* ]] || die "archive contains an unsafe path: $entry"
  case "/$entry/" in
    */../*|//*) die "archive contains an unsafe path: $entry" ;;
  esac
  [[ "$entry" == package || "$entry" == package/* ]] || \
    die "archive entry is outside package: $entry"
done < <(tar -tzf "$work_dir/$asset")

mkdir "$work_dir/unpacked"
tar -xzf "$work_dir/$asset" -C "$work_dir/unpacked" --strip-components=1 \
  --no-same-owner --no-same-permissions

new_binary="$work_dir/unpacked/bin/$executable"
[[ -x "$new_binary" ]] || die "archive did not contain an executable bin/$executable"
new_version="$({ "$new_binary" --version 2>/dev/null || true; } | head -n 1)"
new_version="${new_version##* }"
new_version="${new_version#v}"
[[ "$new_version" == "$version" ]] || \
  die "downloaded binary reported unexpected version: $new_version"

staged="$(mktemp "$install_dir/.${executable}-install.XXXXXXXX")"
rm "$staged"
mv "$new_binary" "$staged"
if [[ -e "$installed_binary" ]]; then
  backup="$(mktemp "$install_dir/.${executable}-backup.XXXXXXXX")"
  rm "$backup"
  mv "$installed_binary" "$backup"
fi

mv "$staged" "$installed_binary"
"$install_dir/$executable" --version >/dev/null 2>&1 || \
  die "installed OpenCode failed to start"

if [[ -n "$backup" ]]; then
  rm -rf "$backup"
  backup=""
fi
printf 'Updated %s to %s in %s.\n' "$name" "$version" "$install_dir"
