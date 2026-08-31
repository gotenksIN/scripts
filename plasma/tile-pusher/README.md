# Windows-style push tiling

KWin assigns Meta+Arrow to its built-in quick-tile actions by default.
This script does not replace those shortcuts automatically.

After you enable the script, open System Settings > Keyboard > Shortcuts > KWin.
Clear Meta+Arrow from the four "Quick Tile Window" actions.
Assign those keys to the four "Cinnamon-style push tiling" actions.
The script retains the Cinnamon action IDs so existing shortcut settings continue to work.

Alternatively, run `./bind-shortcuts.sh` after you enable the script to apply these shortcut changes through the KGlobalAccel D-Bus API.
