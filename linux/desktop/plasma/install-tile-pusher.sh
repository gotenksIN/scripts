#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf 'Usage: %s [--bind-shortcuts]\n' "${0##*/}"
    printf 'Install and enable push tiling for your KWin session.\n'
    printf 'Use --bind-shortcuts to assign Meta+Arrow to push tiling.\n'
}

bind_shortcuts=false
case ${1:-} in
    -h|--help) usage; exit 0 ;;
    --bind-shortcuts) bind_shortcuts=true; shift ;;
esac
if (( $# )); then
    usage >&2
    exit 1
fi

for tool in 7z kpackagetool6 kwriteconfig6 gdbus; do
    command -v "$tool" >/dev/null || {
        printf '%s is required to install push tiling.\n' "$tool" >&2
        exit 1
    }
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
package="$temporary/push-tiles.kwinscript"
"$script_dir/build-tile-pusher.sh" "$package"

if kpackagetool6 --type=KWin/Script --show push-tiles >/dev/null 2>&1; then
    kpackagetool6 --type=KWin/Script --upgrade "$package"
else
    kpackagetool6 --type=KWin/Script --install "$package"
fi
kwriteconfig6 --file kwinrc --group Plugins --key push-tilesEnabled --type bool true

scripting_call() {
    local method=$1
    shift
    gdbus call --session --dest org.kde.KWin --object-path /Scripting \
        --method "org.kde.kwin.Scripting.$method" "$@"
}

wait_for_loaded() {
    local expected=$1
    local attempt
    for ((attempt = 0; attempt < 50; attempt++)); do
        if [[ $(scripting_call isScriptLoaded 'push-tiles') == "($expected,)" ]]; then
            return
        fi
        sleep 0.1
    done
    printf 'Timed out waiting for push-tiles loaded=%s.\n' "$expected" >&2
    exit 1
}

if [[ $(scripting_call isScriptLoaded 'push-tiles') == '(true,)' ]]; then
    scripting_call unloadScript 'push-tiles' >/dev/null
    wait_for_loaded false
fi
scripting_call start >/dev/null
wait_for_loaded true

if "$bind_shortcuts"; then
    "$script_dir/tile-pusher/bind-shortcuts.sh"
fi
printf 'Push tiling is installed and enabled.\n'
