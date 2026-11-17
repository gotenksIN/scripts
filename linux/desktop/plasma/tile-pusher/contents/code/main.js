const MAXIMIZE_RESTORE = 0;
const MAXIMIZE_FULL = 3;
const windows = new Map();
const topBottomHalves = readConfig("topBottomHalves", false);
const crossMonitorWrap = readConfig("crossMonitorWrap", true);
const debug = readConfig("debug", false);
const TRANSITIONS = {
    FLOAT: { Up: "MAX", Down: "MINIMIZE", Left: "LEFT", Right: "RIGHT" },
    MAX: { Up: null, Down: "RESTORE", Left: "LEFT", Right: "RIGHT" },
    LEFT: { Up: "TL", Down: "BL", Left: "WRAP", Right: "FLOAT" },
    RIGHT: { Up: "TR", Down: "BR", Left: "FLOAT", Right: "WRAP" },
    TOP: { Up: "MAX", Down: "FLOAT", Left: "TL", Right: "TR" },
    BOTTOM: { Up: "FLOAT", Down: "MINIMIZE", Left: "BL", Right: "BR" },
    TL: { Up: "MAX", Down: "LEFT", Left: "WRAP", Right: "FLOAT" },
    TR: { Up: "MAX", Down: "RIGHT", Left: "FLOAT", Right: "WRAP" },
    BL: { Up: "LEFT", Down: "MINIMIZE", Left: "WRAP", Right: "FLOAT" },
    BR: { Up: "RIGHT", Down: "MINIMIZE", Left: "FLOAT", Right: "WRAP" },
    CUSTOM: { Up: "MAX", Down: "FLOAT", Left: "LEFT", Right: "RIGHT" }
};
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
        if (!transitioning && detectState(w) !== ctx.state) {
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

function applyTarget(w, target, wrap) {
    const source = getState(w);
    const ctx = windows.get(w);
    if (target === "MINIMIZE") {
        if (w.minimizable) workspace.slotWindowMinimize();
        return;
    }
    if (target === "MAX") {
        if (!w.maximizable) return;
        ctx.preMaxState = source;
        w.setMaximize(true, true);
    } else {
        // Cancel pending maximization even before the client acknowledges it.
        w.setMaximize(false, false);
        if (target === "FLOAT") {
            untileToFloat(w);
        } else {
            applyQuickTile(w, target, wrap);
        }
        ctx.preMaxState = null;
    }
    // Native wrap can move to the opposite edge of the adjacent output.
    ctx.state = wrap ? detectState(w) : target;
    if (debug) console.info("push-tiles: " + source + " -> " + ctx.state);
}

function push(direction) {
    const w = activeWindow();
    if (!w) return;
    const source = getState(w);
    let target = TRANSITIONS[source][direction];
    if (topBottomHalves && source === "FLOAT") {
        if (direction === "Up") target = "TOP";
        if (direction === "Down") target = "BOTTOM";
    }
    if (!target) return;
    const wrap = target === "WRAP";
    if (wrap) {
        if (!crossMonitorWrap) return;
        target = source;
    }
    if (target === "RESTORE") {
        const previous = windows.get(w).preMaxState;
        target = previous === "TL" || previous === "TR" || previous === "TOP"
            ? previous : "FLOAT";
    }
    applyTarget(w, target, wrap);
}

registerShortcut(
    "Cinnamon Push Tile Up",
    "Cinnamon-style push tiling up",
    "",
    transition(function() { push("Up"); })
);

registerShortcut(
    "Cinnamon Push Tile Down",
    "Cinnamon-style push tiling down",
    "",
    transition(function() { push("Down"); })
);

registerShortcut(
    "Cinnamon Push Tile Left",
    "Cinnamon-style push tiling left",
    "",
    transition(function() { push("Left"); })
);

registerShortcut(
    "Cinnamon Push Tile Right",
    "Cinnamon-style push tiling right",
    "",
    transition(function() { push("Right"); })
);

registerShortcut(
    "Cinnamon Push Tile Top Half",
    "Snap window to the top half",
    "",
    transition(function() {
        const w = activeWindow();
        if (w) applyTarget(w, "TOP", false);
    })
);

registerShortcut(
    "Cinnamon Push Tile Bottom Half",
    "Snap window to the bottom half",
    "",
    transition(function() {
        const w = activeWindow();
        if (w) applyTarget(w, "BOTTOM", false);
    })
);

workspace.windowRemoved.connect(clearState);
workspace.windowAdded.connect(watchWindow);
workspace.windowList().forEach(watchWindow);
