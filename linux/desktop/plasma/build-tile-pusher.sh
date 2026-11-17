#!/usr/bin/env bash

set -euo pipefail

command -v 7z >/dev/null || {
    printf '7z is required to build the KWin script package.\n' >&2
    exit 1
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
package_dir="$script_dir/tile-pusher"
output=${1:-"$script_dir/push-tiles.kwinscript"}
if [[ $output != /* ]]; then
    output="$PWD/$output"
fi

temporary="$output.$$.tmp"
trap 'rm -f -- "$temporary"' EXIT
rm -f -- "$temporary"

(
    cd -- "$package_dir"
    7z a -tzip "$temporary" metadata.json contents
)
mv -f -- "$temporary" "$output"
