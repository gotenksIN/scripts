# Windows-style push tiling

This KWin script provides directional push tiling for KDE Plasma 6 that matches Windows 11 `Win+Arrow` snap behavior.

## Install

Run the installer from `linux/desktop/plasma/` to build the package, install or upgrade `push-tiles`, enable the script, and bind `Meta+Arrow`:

```bash
./install-tile-pusher.sh --bind-shortcuts
```

Omit `--bind-shortcuts` if you configure shortcuts yourself.

To build and install manually from `linux/desktop/plasma/`:

```bash
./build-tile-pusher.sh
kpackagetool6 --type=KWin/Script --install push-tiles.kwinscript
```

Use `--upgrade` instead of `--install` when updating an existing installation.
Enable **Windows-style Push Tiling** in **System Settings > Window Management > KWin Scripts**.

## Configure shortcuts

KWin assigns `Meta+Arrow` to its built-in quick-tile actions by default.
After you enable `push-tiles`, run `./tile-pusher/bind-shortcuts.sh` to reassign `Meta+Arrow` through the KGlobalAccel D-Bus API.
Run `./tile-pusher/bind-shortcuts.sh --restore` to return `Meta+Arrow` to KWin's built-in quick-tile actions.

To configure shortcuts manually, open **System Settings > Keyboard > Shortcuts > KWin**:

1. Clear `Meta+Arrow` from **Quick Tile Window to the Left**, **Quick Tile Window to the Top**, **Quick Tile Window to the Right**, and **Quick Tile Window to the Bottom**.
2. Assign `Meta+Arrow` to **Cinnamon-style push tiling left**, **Cinnamon-style push tiling up**, **Cinnamon-style push tiling right**, and **Cinnamon-style push tiling down**.

The script keeps the Cinnamon action IDs so existing shortcut settings continue to work.
You can also assign shortcuts such as `Meta+Alt+Up` and `Meta+Alt+Down` to **Snap window to the top half** and **Snap window to the bottom half**.
Use KWin's built-in **Window to Previous Screen** and **Window to Next Screen** shortcuts (`Meta+Shift+Left` and `Meta+Shift+Right` by default) to move tiled or maximized windows directly between monitors.

## Window transitions

By default, directional pushes follow Windows 11 snap transitions:

| Current state | `Meta+Up` | `Meta+Down` | `Meta+Left` | `Meta+Right` |
| --- | --- | --- | --- | --- |
| `FLOAT` | `MAX` | `MINIMIZE` | `LEFT` | `RIGHT` |
| `MAX` | No-op | Prior tile (`TL`, `TR`, `TOP`) or `FLOAT` | `LEFT` | `RIGHT` |
| `LEFT` | `TL` | `BL` | Adjacent screen `RIGHT` | `FLOAT` |
| `RIGHT` | `TR` | `BR` | `FLOAT` | Adjacent screen `LEFT` |
| `TOP` | `MAX` | `FLOAT` | `TL` | `TR` |
| `BOTTOM` | `FLOAT` | `MINIMIZE` | `BL` | `BR` |
| `TL` | `MAX` | `LEFT` | Adjacent screen `TR` | `FLOAT` |
| `TR` | `MAX` | `RIGHT` | `FLOAT` | Adjacent screen `TL` |
| `BL` | `LEFT` | `MINIMIZE` | Adjacent screen `BR` | `FLOAT` |
| `BR` | `RIGHT` | `MINIMIZE` | `FLOAT` | Adjacent screen `BL` |
| `CUSTOM` | `MAX` | `FLOAT` | `LEFT` | `RIGHT` |

## Options

Open **System Settings > Window Management > KWin Scripts** and select the configure button on **Windows-style Push Tiling** to adjust these options:

- **Use top and bottom halves before maximizing or minimizing** (`topBottomHalves`, off by default): Snaps floating windows to `TOP` on `Meta+Up` and `BOTTOM` on `Meta+Down` instead of maximizing or minimizing directly.
- **Move to the adjacent monitor when you push the same edge again** (`crossMonitorWrap`, on by default): Wraps tiled windows across monitors when you push an outer edge again.
- **Log tiling transitions** (`debug`, off by default): Writes transition logs to the KWin user journal (`journalctl --user -u plasma-kwin_wayland.service -f`).

Disable and re-enable the script after you apply option changes.
