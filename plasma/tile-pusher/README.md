# Windows-style Push Tiling

KWin already assigns Meta+Arrow to its built-in quick-tile actions, so this
script does not replace those shortcuts automatically.

After enabling the script, open System Settings > Keyboard > Shortcuts > KWin.
Clear Meta+Arrow from the four "Quick Tile Window" actions, then assign those
keys to the four "Cinnamon-style push tiling" actions. The Cinnamon action IDs
are retained so existing shortcut settings continue to work.

Alternatively, run `./bind-shortcuts.sh` after enabling the script to make
those changes through KGlobalAccel's D-Bus API.
