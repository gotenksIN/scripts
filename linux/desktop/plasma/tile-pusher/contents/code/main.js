const MAXIMIZE_RESTORE = 0;
const MAXIMIZE_FULL = 3;
const windows = new Map();
var transitioning = false;

function activeWindow() {
    var w = workspace.activeWindow;
    if (!w) return null;
    if (!w.managed || w.specialWindow || w.minimized) return null;
    if (!w.resizeable || !w.moveable) return null;
    return w;
}

function isMaximized(w) {
    return w.maximizeMode === MAXIMIZE_FULL;
}

function getState(w) {
    watchWindow(w);
    return windows.get(w).state || detectState(w);
}

function setState(w, s) {
    windows.get(w).state = s;
}

function clearState(w) {
    windows.delete(w);
}

function stateFromRelativeGeometry(rect) {
    var left = rect.x <= 0.01;
    var right = rect.x + rect.width >= 0.99;
    var top = rect.y <= 0.01;
    var bottom = rect.y + rect.height >= 0.99;
    var halfWidth = rect.width >= 0.05 && rect.width <= 0.95;
    var halfHeight = rect.height >= 0.05 && rect.height <= 0.95;

    if (left && right && top && halfHeight) return "TOP";
    if (left && right && bottom && halfHeight) return "BOTTOM";
    if (left && top && bottom && halfWidth) return "LEFT";
    if (right && top && bottom && halfWidth) return "RIGHT";
    if (left && top && halfWidth && halfHeight) return "TL";
    if (right && top && halfWidth && halfHeight) return "TR";
    if (left && bottom && halfWidth && halfHeight) return "BL";
    if (right && bottom && halfWidth && halfHeight) return "BR";
    return "CUSTOM";
}

function detectState(w) {
    if (isMaximized(w)) return "MAX";
    if (!w.tile) return "FLOAT";
    return stateFromRelativeGeometry(w.tile.relativeGeometry);
}

function watchWindow(w) {
    if (!w || !w.managed || w.specialWindow) return;
    if (windows.has(w) && windows.get(w).watched) return;
    const ctx = { state: null, preMaxState: null, watched: true };
    windows.set(w, ctx);
    function invalidate() {
        if (!transitioning) {
            ctx.state = null;
            ctx.preMaxState = null;
        }
    }
    w.interactiveMoveResizeFinished.connect(invalidate);
    w.outputChanged.connect(invalidate);
    w.tileChanged.connect(invalidate);
    w.maximizedChanged.connect(invalidate);
    w.closed.connect(function() { clearState(w); });
}

function transition(handler) {
    return function() {
        transitioning = true;
        try {
            handler();
        } finally {
            transitioning = false;
        }
    };
}

function untileToFloat(w) {
    const out = w.output;
    if (w.tile) w.tile.unmanage(w);
    // Restore can change the pending output before Wayland updates w.output.
    workspace.sendClientToScreen(w, out);
}

function applyQuickTile(w, targetState, allowCrossMonitorWrap) {
    const slots = {
        LEFT: "slotWindowQuickTileLeft",
        RIGHT: "slotWindowQuickTileRight",
        TOP: "slotWindowQuickTileTop",
        BOTTOM: "slotWindowQuickTileBottom",
        TL: "slotWindowQuickTileTopLeft",
        TR: "slotWindowQuickTileTopRight",
        BL: "slotWindowQuickTileBottomLeft",
        BR: "slotWindowQuickTileBottomRight"
    };
    const source = getState(w);
    const cornerToHalf =
        ((source === "TL" || source === "BL") && targetState === "LEFT") ||
        ((source === "TR" || source === "BR") && targetState === "RIGHT") ||
        ((source === "TL" || source === "TR") && targetState === "TOP") ||
        ((source === "BL" || source === "BR") && targetState === "BOTTOM");
    if (w.maximizeMode !== MAXIMIZE_RESTORE) w.setMaximize(false, false);
    if (w.tile !== null && (cornerToHalf ||
        (source === targetState && !allowCrossMonitorWrap))) {
        untileToFloat(w);
    }
    workspace[slots[targetState]]();
}

function tileTop() {
    applyQuickTile(activeWindow(), "TOP", false);
}
function tileBottom() {
    applyQuickTile(activeWindow(), "BOTTOM", false);
}
function tileLeft() {
    applyQuickTile(activeWindow(), "LEFT", false);
}
function tileRight() {
    applyQuickTile(activeWindow(), "RIGHT", false);
}
function tileTopLeft() {
    applyQuickTile(activeWindow(), "TL", false);
}
function tileTopRight() {
    applyQuickTile(activeWindow(), "TR", false);
}
function tileBottomLeft() {
    applyQuickTile(activeWindow(), "BL", false);
}
function tileBottomRight() {
    applyQuickTile(activeWindow(), "BR", false);
}
function maximizeWindow(maximize) {
    var w = activeWindow();
    if (!w || !w.maximizable) return;
    w.setMaximize(maximize, maximize);
    setState(w, maximize ? "MAX" : "FLOAT");
}
function minimize() {
    var w = activeWindow();
    if (!w || !w.minimizable) return;
    workspace.slotWindowMinimize();
}

function onUp() {
    var w = activeWindow();
    if (!w) return;

    var s = getState(w);

    if (s === "MAX") {
        return;
    }

    if (s === "TOP" || s === "TL" || s === "TR") {
        maximizeWindow(true);
        return;
    }

    if (s === "LEFT" || s === "BL") {
        tileTopLeft();
        setState(w, "TL");
        return;
    }

    if (s === "RIGHT" || s === "BR") {
        tileTopRight();
        setState(w, "TR");
        return;
    }

    if (s === "BOTTOM") {
        tileTop();
        setState(w, "TOP");
        return;
    }

    tileTop();
    setState(w, "TOP");
}

function onDown() {
    var w = activeWindow();
    if (!w) return;

    var s = getState(w);

    if (s === "MAX") {
        maximizeWindow(false);
        return;
    }

    if (s === "BOTTOM" || s === "BL" || s === "BR") {
        minimize();
        return;
    }

    if (s === "TOP" || s === "FLOAT") {
        tileBottom();
        setState(w, "BOTTOM");
        return;
    }

    if (s === "LEFT" || s === "TL") {
        tileBottomLeft();
        setState(w, "BL");
        return;
    }

    if (s === "RIGHT" || s === "TR") {
        tileBottomRight();
        setState(w, "BR");
        return;
    }
}

function onLeft() {
    var w = activeWindow();
    if (!w) return;

    var s = getState(w);

    if (s === "LEFT") {
        return;
    }

    if (s === "TOP" || s === "TR") {
        tileTopLeft();
        setState(w, "TL");
        return;
    }

    if (s === "BOTTOM" || s === "BR") {
        tileBottomLeft();
        setState(w, "BL");
        return;
    }

    tileLeft();
    setState(w, "LEFT");
}

function onRight() {
    var w = activeWindow();
    if (!w) return;

    var s = getState(w);

    if (s === "RIGHT") {
        return;
    }

    if (s === "TOP" || s === "TL") {
        tileTopRight();
        setState(w, "TR");
        return;
    }

    if (s === "BOTTOM" || s === "BL") {
        tileBottomRight();
        setState(w, "BR");
        return;
    }

    tileRight();
    setState(w, "RIGHT");
}

registerShortcut(
    "Cinnamon Push Tile Up",
    "Cinnamon-style push tiling up",
    "",
    transition(onUp)
);

registerShortcut(
    "Cinnamon Push Tile Down",
    "Cinnamon-style push tiling down",
    "",
    transition(onDown)
);

registerShortcut(
    "Cinnamon Push Tile Left",
    "Cinnamon-style push tiling left",
    "",
    transition(onLeft)
);

registerShortcut(
    "Cinnamon Push Tile Right",
    "Cinnamon-style push tiling right",
    "",
    transition(onRight)
);

workspace.windowRemoved.connect(function(w) {
    clearState(w);
});

workspace.windowAdded.connect(watchWindow);
workspace.windowList().forEach(watchWindow);
