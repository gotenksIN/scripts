var stateByWindow = {};

function activeWindow() {
    var w = workspace.activeWindow;
    if (!w) return null;
    if (!w.normalWindow) return null;
    return w;
}

function wid(w) {
    try {
        return String(w.internalId);
    } catch (e) {
        return String(w);
    }
}

function isMaximized(w) {
    return !!(w.maximizedHorizontally && w.maximizedVertically);
}

function getState(w) {
    if (isMaximized(w)) {
        return "MAX";
    }
    return stateByWindow[wid(w)] || "FLOAT";
}

function setState(w, s) {
    stateByWindow[wid(w)] = s;
}

function clearState(w) {
    delete stateByWindow[wid(w)];
}

function maximizeArea(w) {
    return workspace.clientArea(KWin.MaximizeArea, w);
}

function placeWindow(w, x, y, width, height) {
    var rect = maximizeArea(w);
    rect.x = x;
    rect.y = y;
    rect.width = width;
    rect.height = height;

    if (isMaximized(w)) {
        w.setMaximize(false, false);
    }

    w.frameGeometry = rect;
}

function tileTop() {
    workspace.slotWindowQuickTileTop();
}
function tileBottom() {
    workspace.slotWindowQuickTileBottom();
}
function tileLeft() {
    var w = activeWindow();
    if (!w) return;

    var area = maximizeArea(w);
    var split = Math.round(area.x + area.width / 2);
    placeWindow(w, area.x, area.y, split - area.x, area.height);
}
function tileRight() {
    var w = activeWindow();
    if (!w) return;

    var area = maximizeArea(w);
    var split = Math.round(area.x + area.width / 2);
    placeWindow(w, split, area.y, area.x + area.width - split, area.height);
}
function tileTopLeft() {
    workspace.slotWindowQuickTileTopLeft();
}
function tileTopRight() {
    workspace.slotWindowQuickTileTopRight();
}
function tileBottomLeft() {
    workspace.slotWindowQuickTileBottomLeft();
}
function tileBottomRight() {
    workspace.slotWindowQuickTileBottomRight();
}
function toggleMaximize() {
    workspace.slotWindowMaximize();
}
function minimize() {
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
        toggleMaximize();
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
        toggleMaximize();
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

    tileRight();
    setState(w, "RIGHT");
}

registerShortcut(
    "Cinnamon Push Tile Up",
    "Cinnamon-style push tiling up",
    "Meta+Up",
    onUp
);

registerShortcut(
    "Cinnamon Push Tile Down",
    "Cinnamon-style push tiling down",
    "Meta+Down",
    onDown
);

registerShortcut(
    "Cinnamon Push Tile Left",
    "Cinnamon-style push tiling left",
    "Meta+Left",
    onLeft
);

registerShortcut(
    "Cinnamon Push Tile Right",
    "Cinnamon-style push tiling right",
    "Meta+Right",
    onRight
);

workspace.windowRemoved.connect(function(w) {
    clearState(w);
});
