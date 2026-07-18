#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
package_dir="$script_dir/tile-pusher"
output=${1:-"$script_dir/push-tiles.kwinscript"}
if [[ $output != /* ]]; then
    output="$PWD/$output"
fi

temporary="$output.$$.tmp"
trap 'rm -f -- "$temporary"' EXIT

(
    cd -- "$package_dir"
    7z a -tzip "$temporary" metadata.json contents README.md bind-shortcuts.sh
)
mv -f -- "$temporary" "$output"
