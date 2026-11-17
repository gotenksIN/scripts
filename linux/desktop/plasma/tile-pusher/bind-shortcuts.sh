#!/usr/bin/env bash

set -euo pipefail

readonly service=org.kde.kglobalaccel
readonly object=/kglobalaccel
readonly method=org.kde.KGlobalAccel.setShortcutKeys

usage() {
    printf 'Usage: %s [--restore]\n' "${0##*/}"
    printf 'Assign Meta+Arrow to push tiling, or restore native quick tiling.\n'
}

restore=false
case ${1:-} in
    -h|--help) usage; exit 0 ;;
    --restore) restore=true; shift ;;
esac
if (( $# )); then
    usage >&2
    exit 1
fi

command -v gdbus >/dev/null || {
    printf 'gdbus is required to configure KGlobalAccel shortcuts.\n' >&2
    exit 1
}

if [[ $(gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.isScriptLoaded 'push-tiles') != '(true,)' ]]; then
    printf 'Load the push-tiles KWin script before configuring shortcuts.\n' >&2
    exit 1
fi

set_shortcut() {
    local action=$1
    local description=$2
    local key=${3:-}
    local keys='@a(ai) []'
    local result
    if [[ -n $key ]]; then
        keys="[([$key],)]"
    fi

    result=$(gdbus call --session --dest "$service" --object-path "$object" \
        --method "$method" \
        "['kwin', '$action', 'KWin', '$description']" "$keys" 4)
    if [[ -n $key && $result != *"$key"* ]]; then
        printf 'Failed to bind %s: %s\n' "$action" "$result" >&2
        exit 1
    fi
}

# Qt encodes Meta+Arrow as the Meta modifier plus the corresponding Qt key.
if "$restore"; then
    set_shortcut "Cinnamon Push Tile Left" "Cinnamon-style push tiling left"
    set_shortcut "Cinnamon Push Tile Up" "Cinnamon-style push tiling up"
    set_shortcut "Cinnamon Push Tile Right" "Cinnamon-style push tiling right"
    set_shortcut "Cinnamon Push Tile Down" "Cinnamon-style push tiling down"
    set_shortcut "Window Quick Tile Left" "Quick Tile Window to the Left" 285212690
    set_shortcut "Window Quick Tile Top" "Quick Tile Window to the Top" 285212691
    set_shortcut "Window Quick Tile Right" "Quick Tile Window to the Right" 285212692
    set_shortcut "Window Quick Tile Bottom" "Quick Tile Window to the Bottom" 285212693
    printf 'Meta+Arrow is now assigned to native quick tiling.\n'
else
    set_shortcut "Window Quick Tile Left" "Quick Tile Window to the Left"
    set_shortcut "Window Quick Tile Top" "Quick Tile Window to the Top"
    set_shortcut "Window Quick Tile Right" "Quick Tile Window to the Right"
    set_shortcut "Window Quick Tile Bottom" "Quick Tile Window to the Bottom"
    set_shortcut "Cinnamon Push Tile Left" "Cinnamon-style push tiling left" 285212690
    set_shortcut "Cinnamon Push Tile Up" "Cinnamon-style push tiling up" 285212691
    set_shortcut "Cinnamon Push Tile Right" "Cinnamon-style push tiling right" 285212692
    set_shortcut "Cinnamon Push Tile Down" "Cinnamon-style push tiling down" 285212693
    printf 'Meta+Arrow is now assigned to Windows-style Push Tiling.\n'
fi
