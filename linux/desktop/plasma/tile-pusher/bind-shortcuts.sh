#!/usr/bin/env bash

set -euo pipefail

readonly service=org.kde.kglobalaccel
readonly object=/kglobalaccel
readonly method=org.kde.KGlobalAccel.setShortcut

command -v gdbus >/dev/null || {
    printf 'gdbus is required to configure KGlobalAccel shortcuts.\n' >&2
    exit 1
}

set_shortcut() {
    local action=$1
    local description=$2
    local keys=$3

    gdbus call --session --dest "$service" --object-path "$object" \
        --method "$method" \
        "['kwin', '$action', 'KWin', '$description']" "$keys" 4 >/dev/null
}

set_shortcut "Window Quick Tile Left" "Quick Tile Window to the Left" '[]'
set_shortcut "Window Quick Tile Top" "Quick Tile Window to the Top" '[]'
set_shortcut "Window Quick Tile Right" "Quick Tile Window to the Right" '[]'
set_shortcut "Window Quick Tile Bottom" "Quick Tile Window to the Bottom" '[]'

# Qt encodes Meta+Arrow as the Meta modifier plus the corresponding Qt key.
set_shortcut "Cinnamon Push Tile Left" "Cinnamon-style push tiling left" '[285212690]'
set_shortcut "Cinnamon Push Tile Up" "Cinnamon-style push tiling up" '[285212691]'
set_shortcut "Cinnamon Push Tile Right" "Cinnamon-style push tiling right" '[285212692]'
set_shortcut "Cinnamon Push Tile Down" "Cinnamon-style push tiling down" '[285212693]'

printf 'Meta+Arrow is now assigned to Windows-style Push Tiling.\n'
