import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Qt.labs.folderlistmodel

// Left sidebar with tabs (router): Apps | Wallpaper | Tools | System | Dev  + music card.
//   qs -c sidebar ipc call sidebar toggle     (niri: Super+Space)
//   qs -c sidebar ipc call sidebar goto 1     (open directly on a tab: 0 apps, 1 wallpaper, 2 tools, 3 system, 4 dev)
ShellRoot {
    id: root

    readonly property int pw: 410
    readonly property string nerd: "CaskaydiaCove Nerd Font"
    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: home + "/.config/niri/scripts/"

    property bool open: false
    property bool shown: false
    property int tab: 0

    // pinned apps (desktop-file ids / names) -- edit this list
    readonly property var pinned: ["firefox", "code", "kitty", "spotify", "thunar",
                                   "io.github.spacingbat3.webcord", "org.blender.Blender", "com.obsproject.Studio"]

    readonly property var tabs: [
        { ic: "", n: "HOME" },
        { ic: "", n: "APPS" },
        { ic: "", n: "WALLPAPER" },
        { ic: "", n: "TOOLS" },
        { ic: "", n: "AUDIO" },
        { ic: "", n: "INTERNET" },
        { ic: "", n: "MONITOR" },
        { ic: "", n: "TASK MANAGER" },
        { ic: "", n: "WEATHER" },
        { ic: "", n: "CALENDAR" },
        { ic: "", n: "DEV" }
    ]

    // weather helpers (WMO codes from Open-Meteo)
    function wxIcon(c, day) {
        if (c === 0) return day ? "" : ""
        if (c <= 2) return day ? "" : ""
        if (c === 3) return ""
        if (c === 45 || c === 48) return ""
        if (c >= 51 && c <= 57) return ""
        if (c >= 61 && c <= 67) return ""
        if (c >= 71 && c <= 77) return ""
        if (c >= 80 && c <= 82) return ""
        if (c === 85 || c === 86) return ""
        if (c >= 95) return ""
        return ""
    }
    function wxText(c) {
        var m = { 0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Rime fog", 51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle", 61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain", 71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains", 80: "Light showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Heavy snow showers", 95: "Thunderstorm", 96: "Thunderstorm with hail", 99: "Severe thunderstorm with hail" }
        return m[c] !== undefined ? m[c] : "—"
    }

    readonly property var tools: [
        { ic: "\uf186", label: "Night light", cmd: [scripts + "nightlight.sh"] },
        { ic: "\uf06e", label: "Navi", cmd: [scripts + "navi.sh", "toggle"] },
        { ic: "\uf0e7", label: "Glitch", cmd: [scripts + "glitch-toggle.sh"] },
        { ic: "\uf1f6", label: "Quiet", cmd: ["swaync-client", "-d", "-sw"] },
        { ic: "\uf023", label: "Lock", cmd: [scripts + "lock.sh"] },
        { ic: "\uf030", label: "Screenshot", cmd: [scripts + "annotate.sh"] },
        { ic: "\uf031", label: "OCR", cmd: [scripts + "ocr.sh"] },
        { ic: "\uf1fc", label: "Colors", cmd: [scripts + "colorpick.sh"] },
        { ic: "\uf03d", label: "Record", cmd: [scripts + "record.sh"] },
        { ic: "\uf249", label: "Note", cmd: [scripts + "note.sh"] },
        { ic: "\uf1ec", label: "Calc", cmd: [scripts + "calc.py"] },
        { ic: "\uf121", label: "Snippets", cmd: [scripts + "snippets.sh"] },
        { ic: "\u265e", label: "Chess", cmd: [scripts + "chess.sh"] },
        { ic: "\uf10b", label: "Phone", cmd: [scripts + "phone.sh"] }
    ]

    // live values for the system tab / wallpaper tab / dev tab
    property real vol: 0
    property bool muted: false
    property real bri: 0
    property string sysInfo: ""
    property string curWall: ""
    property var projects: []

    onOpenChanged: {
        if (open) {
            shown = true; hideTimer.stop()
            if (tab === 2) wallP.running = true
            if (tab === 10) projP.running = true
        } else hideTimer.restart()
    }
    Timer { id: hideTimer; interval: 280; onTriggered: root.shown = false }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
        function goto(n: int): void { root.tab = n; root.open = true }
    }

    // ---------- now-playing card state ----------
    property bool playerOpen: false
    property bool playerShown: false
    onPlayerOpenChanged: { if (playerOpen) { playerShown = true; pHide.stop() } else pHide.restart() }
    Timer { id: pHide; interval: 280; onTriggered: root.playerShown = false }

    IpcHandler {
        target: "player"
        function toggle(): void { root.playerOpen = !root.playerOpen }
        function show(): void { root.playerOpen = true }
        function hide(): void { root.playerOpen = false }
    }

    function pickPlayer() {
        var l = Mpris.players.values
        var best = null
        for (var i = 0; i < l.length; i++) {
            if ((l[i].identity || "").toLowerCase().indexOf("spotify") >= 0) return l[i]
            if (!best) best = l[i]
        }
        return best
    }
    readonly property var player: pickPlayer()

    function fmt(sec) {
        if (!(sec >= 0)) return "0:00"
        var m = Math.floor(sec / 60), r = Math.floor(sec % 60)
        return m + ":" + (r < 10 ? "0" : "") + r
    }


    // ---------- OSD (volume / brightness / mic) ----------
    property string osdKind: "vol"
    property int osdValue: 0
    property bool osdMuted: false
    property bool osdOpen: false
    property bool osdShown: false
    Timer { id: osdHide; interval: 1500; onTriggered: root.osdOpen = false }
    Timer { id: osdOff; interval: 260; onTriggered: root.osdShown = false }
    onOsdOpenChanged: { if (osdOpen) { osdShown = true; osdOff.stop() } else osdOff.restart() }
    IpcHandler {
        target: "osd"
        function popup(kind: string, value: int, muted: bool): void {
            root.osdKind = kind; root.osdValue = value; root.osdMuted = muted
            root.osdOpen = true; osdHide.restart()
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ---------- app matching helpers ----------
    function norm(s) { return (s || "").toLowerCase().replace(".desktop", "") }

    function topMatchesEntry(top, entry, name) {
        if (!top) return false
        var a = norm(top.appId)
        var id = entry ? norm(entry.id) : norm(name)
        if (a === "") return false
        return a === id || a === norm(name) || id.endsWith("." + a) || a.endsWith("." + id)
            || (entry && a === norm(entry.name))
    }

    function findTop(entry, name) {
        var list = ToplevelManager.toplevels.values
        for (var i = 0; i < list.length; i++)
            if (topMatchesEntry(list[i], entry, name)) return list[i]
        return null
    }

    function isPinnedTop(top) {
        var n = DesktopEntries.applications.values.length
        for (var i = 0; i < pinned.length; i++) {
            var e = DesktopEntries.heuristicLookup(pinned[i])
            if (topMatchesEntry(top, e, pinned[i])) return true
        }
        return false
    }

    // ---------- data sources (only polled while the matching tab is visible) ----------
    Process { id: volP; command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { onStreamFinished: { var m = this.text.match(/([0-9.]+)/); if (m) root.vol = parseFloat(m[1]); root.muted = this.text.indexOf("MUTED") >= 0 } } }
    Process { id: briP; command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector { onStreamFinished: { var v = parseFloat(this.text); if (!isNaN(v)) root.bri = v / 100 } } }
    Process { id: loadP; command: ["sh", "-c", "echo \"$(cut -d' ' -f1 /proc/loadavg) · $(free -m | awk '/Mem/{printf \"%.1f/%.1f GB\", $3/1024, $2/1024}')\""]
        stdout: StdioCollector { onStreamFinished: root.sysInfo = this.text.trim() } }
    Process { id: wallP; command: ["sh", "-c", "cat ~/.cache/niri-wallpaper 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.curWall = this.text.trim() } }
    Process { id: projP; command: [root.scripts + "projects.sh", "--list"]
        stdout: StdioCollector { onStreamFinished: root.projects = this.text.trim().split("\n").filter(function(l) { return l.length > 0 }) } }

    onTabChanged: {
        if (tab === 2) { wallP.running = true; wallView.positionViewAtBeginning() }
        if (tab === 10) projP.running = true
    }

    Timer { id: volT; interval: 90; onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", root.vol.toFixed(2)]) }
    Timer { id: briT; interval: 90; onTriggered: Quickshell.execDetached(["brightnessctl", "set", Math.max(5, Math.round(root.bri * 100)) + "%"]) }

    // ---------- the sidebar window ----------
    PanelWindow {
        id: win
        visible: root.shown
        anchors { left: true; top: true; bottom: true }
        margins { top: 58; bottom: 12; left: 12 }
        implicitWidth: root.pw + 24
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            id: panel
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.pw
            x: root.open ? 0 : -(width + 24)
            Behavior on x { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
            radius: 22
            color: "#f20d0b14"
            border.color: "#3aa77bff"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // ----- router: tab grid (2 rows) -----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 98
                    radius: 17
                    color: "#12ffffff"
                    Grid {
                        anchors.centerIn: parent
                        columns: 6
                        spacing: 4
                        Repeater {
                            model: root.tabs
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: 43; height: 40; radius: 12
                                color: root.tab === index ? "#44a77bff" : (tbArea.containsMouse ? "#20a77bff" : "transparent")
                                Text { anchors.centerIn: parent; text: modelData.ic; font.pixelSize: 19; font.family: root.nerd
                                       color: root.tab === index ? "#c0a0ff" : "#8a86a6" }
                                MouseArea { id: tbArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.tab = index }
                            }
                        }
                    }
                }
                Text {
                    Layout.leftMargin: 6
                    text: root.tabs[root.tab].n
                    color: "#a77bff"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 3; font.family: root.nerd
                }

                // ----- content area (one tab visible at a time) -----
                Item {
                    id: content
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // ===== 1: APPS =====
                    Flickable {
                        id: appsView
                        anchors.fill: parent
                        anchors.rightMargin: 8
                        visible: root.tab === 1
                        contentHeight: appsCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: appsCol
                            width: appsView.width
                            spacing: 5

                            Rectangle {
                                width: parent.width; height: 54; radius: 16
                                color: allArea.containsMouse ? "#44a77bff" : "#22a77bff"
                                Row { anchors.centerIn: parent; spacing: 10
                                    Text { text: "\uf303"; color: "#c0a0ff"; font.pixelSize: 24; font.family: root.nerd; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "All apps"; color: "#ffffff"; font.pixelSize: 15; font.family: root.nerd; anchors.verticalCenter: parent.verticalCenter } }
                                MouseArea { id: allArea; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { Quickshell.execDetached(["rofi", "-show", "drun", "-theme", root.home + "/.config/niri/rofi.rasi"]); root.open = false } }
                            }

                            Repeater {
                                model: root.pinned
                                delegate: Item {
                                    id: tile
                                    required property string modelData
                                    readonly property var entry: { var n = DesktopEntries.applications.values.length; return DesktopEntries.heuristicLookup(modelData) }
                                    readonly property var tl: root.findTop(entry, modelData)
                                    visible: entry !== null && entry !== undefined
                                    width: appsCol.width
                                    height: visible ? 58 : 0
                                    Rectangle { anchors.fill: parent; radius: 16
                                        color: tileArea.containsMouse ? "#30a77bff" : (tile.tl && tile.tl.activated ? "#1ea77bff" : "transparent") }
                                    Rectangle { visible: tile.tl !== null; x: 3; anchors.verticalCenter: parent.verticalCenter
                                        width: 4; height: tile.tl && tile.tl.activated ? 24 : 8; radius: 2
                                        color: tile.tl && tile.tl.activated ? "#8fe07a" : "#a77bff" }
                                    Image { x: 16; anchors.verticalCenter: parent.verticalCenter; width: 38; height: 38
                                        sourceSize.width: 76; sourceSize.height: 76
                                        source: tile.entry ? Quickshell.iconPath(tile.entry.icon, "application-x-executable") : "" }
                                    Text { x: 68; width: parent.width - 78; anchors.verticalCenter: parent.verticalCenter
                                        text: tile.entry ? tile.entry.name : ""; color: "#e6e2f7"; font.pixelSize: 15; font.family: root.nerd; elide: Text.ElideRight }
                                    MouseArea { id: tileArea; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { if (tile.tl) tile.tl.activate(); else if (tile.entry) tile.entry.execute(); root.open = false } }
                                }
                            }

                            Repeater {
                                model: ToplevelManager.toplevels
                                delegate: Item {
                                    id: other
                                    required property var modelData
                                    readonly property var entry: { var n = DesktopEntries.applications.values.length; return DesktopEntries.heuristicLookup(modelData.appId) }
                                    visible: !root.isPinnedTop(modelData)
                                    width: appsCol.width
                                    height: visible ? 58 : 0
                                    Rectangle { anchors.fill: parent; radius: 16; color: otherArea.containsMouse ? "#30a77bff" : "transparent" }
                                    Rectangle { x: 3; anchors.verticalCenter: parent.verticalCenter
                                        width: 4; height: other.modelData.activated ? 24 : 8; radius: 2
                                        color: other.modelData.activated ? "#8fe07a" : "#a77bff" }
                                    Image { x: 16; anchors.verticalCenter: parent.verticalCenter; width: 38; height: 38
                                        sourceSize.width: 76; sourceSize.height: 76
                                        source: Quickshell.iconPath(other.entry ? other.entry.icon : other.modelData.appId, "application-x-executable") }
                                    Text { x: 68; width: parent.width - 78; anchors.verticalCenter: parent.verticalCenter
                                        text: other.entry ? other.entry.name : other.modelData.appId; color: "#e6e2f7"; font.pixelSize: 15; font.family: root.nerd; elide: Text.ElideRight }
                                    MouseArea { id: otherArea; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { other.modelData.activate(); root.open = false } }
                                }
                            }
                        }
                    }
                    ScrollHint { target: appsView; active: root.tab === 1 }

                    // ===== 2: WALLPAPERS =====
                    ListView {
                        id: wallView
                        anchors.fill: parent
                        anchors.rightMargin: 8
                        visible: root.tab === 2
                        spacing: 10
                        topMargin: 2
                        bottomMargin: 8
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: FolderListModel {
                            folder: "file://" + root.home + "/Pictures/Wallpapers"
                            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                            showDirs: false
                            sortField: FolderListModel.Name
                        }
                        delegate: Item {
                            id: wd
                            required property string filePath
                            required property url fileUrl
                            width: wallView.width
                            height: Math.round(wallView.width * 0.5625)
                            Image { id: wimg; anchors.fill: parent; source: wd.fileUrl
                                sourceSize.width: 560; sourceSize.height: 315
                                fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false }
                            Rectangle { id: wmask; anchors.fill: parent; radius: 14; visible: false; layer.enabled: true }
                            MultiEffect { anchors.fill: parent; source: wimg; maskEnabled: true; maskSource: wmask; visible: wimg.status === Image.Ready }
                            Rectangle { anchors.fill: parent; radius: 14; color: "#1a1626"; visible: wimg.status !== Image.Ready }
                            Rectangle { anchors.fill: parent; radius: 14; color: "transparent"
                                border.width: wd.filePath === root.curWall ? 3 : (wmArea.containsMouse ? 2 : 0)
                                border.color: wd.filePath === root.curWall ? "#8fe07a" : "#a77bff" }
                            MouseArea { id: wmArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: { root.curWall = wd.filePath; Quickshell.execDetached([root.scripts + "wallpaper.sh", wd.filePath]) } }
                        }
                    }
                    ScrollHint { target: wallView; active: root.tab === 2 }

                    // ===== 3: TOOLS =====
                    Flickable {
                        id: toolsView
                        anchors.fill: parent
                        anchors.rightMargin: 8
                        visible: root.tab === 3
                        contentHeight: toolsGrid.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        Grid {
                            id: toolsGrid
                            columns: 3
                            spacing: 8
                            width: toolsView.width
                            Repeater {
                                model: root.tools
                                delegate: Rectangle {
                                    required property var modelData
                                    width: (toolsGrid.width - 16) / 3
                                    height: 92; radius: 16
                                    color: tlArea.containsMouse ? "#38a77bff" : "#12ffffff"
                                    Column { anchors.centerIn: parent; spacing: 6
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.ic; color: "#b896ff"; font.pixelSize: 30; font.family: root.nerd }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#e6e2f7"; font.pixelSize: 12; font.family: root.nerd } }
                                    MouseArea { id: tlArea; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { Quickshell.execDetached(modelData.cmd); root.open = false } }
                                }
                            }
                        }
                    }
                    ScrollHint { target: toolsView; active: root.tab === 3 }

                    // ===== 10: DEV (projects) =====
                    Flickable {
                        id: devView
                        anchors.fill: parent
                        anchors.rightMargin: 8
                        visible: root.tab === 10
                        contentHeight: devCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: devCol
                            width: devView.width
                            spacing: 5
                            Rectangle {
                                width: parent.width; height: 54; radius: 16
                                color: lgArea.containsMouse ? "#44a77bff" : "#22a77bff"
                                Row { anchors.centerIn: parent; spacing: 10
                                    Text { text: "\uf1d3"; color: "#8fe07a"; font.pixelSize: 20; font.family: root.nerd; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "lazygit"; color: "#ffffff"; font.pixelSize: 15; font.family: root.nerd; anchors.verticalCenter: parent.verticalCenter } }
                                MouseArea { id: lgArea; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { Quickshell.execDetached(["kitty", "--class", "lazygit", "-e", "lazygit"]); root.open = false } }
                            }
                            Text { text: "PROJECTS"; color: "#8a86a6"; font.pixelSize: 11; font.letterSpacing: 3; font.family: root.nerd; topPadding: 8; bottomPadding: 2; leftPadding: 4 }
                            Repeater {
                                model: root.projects
                                delegate: Rectangle {
                                    required property string modelData
                                    width: devCol.width; height: 48; radius: 14
                                    color: prjArea.containsMouse ? "#30a77bff" : "transparent"
                                    Row { anchors.verticalCenter: parent.verticalCenter; x: 14; spacing: 12
                                        Text { text: "\uf07b"; color: "#a77bff"; font.pixelSize: 18; font.family: root.nerd; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: modelData.split("/").pop(); width: devCol.width - 64; elide: Text.ElideRight; color: "#e6e2f7"; font.pixelSize: 15; font.family: root.nerd; anchors.verticalCenter: parent.verticalCenter } }
                                    MouseArea { id: prjArea; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { Quickshell.execDetached(["code", modelData]); Quickshell.execDetached(["kitty", "-d", modelData]); root.open = false } }
                                }
                            }
                        }
                    }
                    ScrollHint { target: devView; active: root.tab === 10 }
                    HomeTab { anchors.fill: parent; sh: root; visible: root.tab === 0; active: root.open && root.tab === 0 }
                    AudioTab { anchors.fill: parent; sh: root; visible: root.tab === 4; active: root.open && root.tab === 4 }
                    NetTab { anchors.fill: parent; sh: root; visible: root.tab === 5; active: root.open && root.tab === 5 }
                    DisplayTab { anchors.fill: parent; sh: root; visible: root.tab === 6; active: root.open && root.tab === 6 }
                    TasksTab { anchors.fill: parent; sh: root; visible: root.tab === 7; active: root.open && root.tab === 7 }
                    WeatherTab { anchors.fill: parent; sh: root; visible: root.tab === 8; active: root.open && root.tab === 8 }
                    CalTab { anchors.fill: parent; sh: root; visible: root.tab === 9; active: root.open && root.tab === 9 }
                }

                // ----- bottom card: clock + battery on the left, buttons on the right -----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    radius: 18
                    color: "#12ffffff"

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        Text { text: Qt.formatDateTime(clock.date, "HH:mm"); color: "#ffffff"; font.pixelSize: 26; font.bold: true; font.family: root.nerd }
                        Text {
                            readonly property real pct: UPower.displayDevice ? (UPower.displayDevice.percentage <= 1 ? UPower.displayDevice.percentage * 100 : UPower.displayDevice.percentage) : -1
                            visible: pct >= 0
                            text: "\uf240  " + Math.round(pct) + "%"
                            color: pct < 20 ? "#e0607a" : "#8fe07a"
                            font.pixelSize: 12; font.family: root.nerd
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Rectangle {
                            width: 46; height: 46; radius: 15
                            color: bellArea.containsMouse ? "#38a77bff" : "transparent"
                            Text { anchors.centerIn: parent; text: "\uf0f3"; color: "#e6e2f7"; font.pixelSize: 20; font.family: root.nerd }
                            MouseArea { id: bellArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: { Quickshell.execDetached(["swaync-client", "-t", "-sw"]); root.open = false } }
                        }
                        Rectangle {
                            visible: root.player !== null
                            width: visible ? 46 : 0; height: 46; radius: 15
                            color: musArea.containsMouse || root.playerOpen ? "#38a77bff" : "transparent"
                            Text { anchors.centerIn: parent; text: "\uf001"; color: root.player && root.player.isPlaying ? "#8fe07a" : "#e6e2f7"; font.pixelSize: 20; font.family: root.nerd }
                            MouseArea { id: musArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.playerOpen = !root.playerOpen }
                        }
                        Rectangle {
                            width: 46; height: 46; radius: 15
                            color: pwrArea.containsMouse ? "#40e0607a" : "transparent"
                            Text { anchors.centerIn: parent; text: "\uf011"; color: "#e0607a"; font.pixelSize: 20; font.family: root.nerd }
                            MouseArea { id: pwrArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: { Quickshell.execDetached([root.scripts + "powermenu.sh"]); root.open = false } }
                        }
                    }
                }
            }
        }
    }


    // ---------- OSD window ----------
    PanelWindow {
        id: osdWin
        visible: root.osdShown
        anchors { bottom: true }
        margins { bottom: 96 }
        implicitWidth: 360
        implicitHeight: 76
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region { }

        Rectangle {
            id: osdBox
            width: 340; height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.osdOpen ? 6 : 24
            opacity: root.osdOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            radius: 22
            color: "#f00d0b14"
            border.color: "#40a77bff"
            border.width: 1

            readonly property bool off: root.osdMuted
            readonly property color accent: off ? "#e0607a" : (root.osdKind === "bri" ? "#8fe07a" : "#a77bff")
            readonly property string icon: {
                if (root.osdKind === "bri") return ""
                if (root.osdKind === "mic") return root.osdMuted ? "" : ""
                if (root.osdMuted) return "\uf026"
                return root.osdValue < 34 ? "" : ""
            }

            Text { id: ic; x: 20; anchors.verticalCenter: parent.verticalCenter; width: 30
                text: osdBox.icon; color: osdBox.accent; font.pixelSize: 24; font.family: root.nerd; horizontalAlignment: Text.AlignHCenter }
            Rectangle { id: bar; x: 64; anchors.verticalCenter: parent.verticalCenter; width: 200; height: 8; radius: 4; color: "#3d3a52"
                visible: root.osdKind !== "mic"
                Rectangle { width: bar.width * Math.max(0, Math.min(1, root.osdValue / 100)); height: bar.height; radius: 4; color: osdBox.accent
                    Behavior on width { NumberAnimation { duration: 120 } } } }
            Text { visible: root.osdKind === "mic"; x: 64; anchors.verticalCenter: parent.verticalCenter
                text: root.osdMuted ? "Mic off" : "Mic on"; color: "#ffffff"; font.pixelSize: 16; font.family: root.nerd }
            Text { visible: root.osdKind !== "mic"; anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
                text: root.osdMuted && root.osdKind === "vol" ? "muted" : root.osdValue + "%"; color: "#ffffff"; font.pixelSize: 16; font.bold: true; font.family: root.nerd }
        }
    }

    // ---------- now-playing card ----------
    PanelWindow {
        id: pwin
        visible: root.playerShown
        anchors { left: true; top: true }
        margins { top: 58; left: root.open ? root.pw + 24 : 12 }
        implicitWidth: 352
        implicitHeight: 524
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Rectangle {
            id: card
            width: 340; height: 512
            x: root.playerOpen ? 0 : -(width + 100)
            Behavior on x { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
            radius: 22
            color: "#f00e0c16"
            border.color: "#40a77bff"
            border.width: 1

            Timer {
                interval: 1000; repeat: true
                running: root.playerOpen && root.player !== null && root.player.isPlaying
                onTriggered: root.player.positionChanged()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                // cover art with rounded corners
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 280; Layout.preferredHeight: 280
                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }
                    Rectangle { id: artMask; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
                    MultiEffect {
                        anchors.fill: parent
                        source: art
                        maskEnabled: true
                        maskSource: artMask
                        visible: art.status === Image.Ready
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 18; color: "#1a1626"
                        visible: art.status !== Image.Ready
                        Text { anchors.centerIn: parent; text: "\uf001"; color: "#a77bff"; font.pixelSize: 72; font.family: "CaskaydiaCove Nerd Font" }
                    }
                }

                // title + moving "equalizer" bars
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        text: root.player && root.player.trackTitle ? root.player.trackTitle : "nothing playing"
                        color: "#ffffff"; font.pixelSize: 19; font.bold: true
                        font.family: "CaskaydiaCove Nerd Font"
                        elide: Text.ElideRight
                    }
                    Item {
                        Layout.preferredWidth: 26; Layout.preferredHeight: 20
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                id: bar
                                required property int index
                                x: index * 7
                                width: 4; radius: 2
                                color: "#8fe07a"
                                property real h: 4
                                height: h
                                y: parent.height - h
                                SequentialAnimation on h {
                                    running: root.playerOpen && root.player !== null && root.player.isPlaying
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 8 + ((bar.index * 5) % 11); duration: 240 + bar.index * 70 }
                                    NumberAnimation { to: 4; duration: 300 + bar.index * 60 }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player && root.player.trackArtist ? root.player.trackArtist : ""
                    color: "#a77bff"; font.pixelSize: 14
                    font.family: "CaskaydiaCove Nerd Font"
                    elide: Text.ElideRight
                }

                // progress bar (click to seek)
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 22
                    Rectangle { id: trackBar; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 4; height: 6; radius: 3; color: "#3d3a52" }
                    Rectangle {
                        anchors.left: trackBar.left; anchors.top: trackBar.top; height: trackBar.height; radius: 3
                        width: root.player && root.player.length > 0 ? trackBar.width * Math.min(1, root.player.position / root.player.length) : 0
                        color: "#a77bff"
                    }
                    MouseArea {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 16
                        onClicked: function(m) {
                            if (root.player && root.player.canSeek && root.player.length > 0)
                                root.player.position = (m.x / width) * root.player.length
                        }
                    }
                    Text { anchors.left: parent.left; anchors.bottom: parent.bottom; text: root.player ? root.fmt(root.player.position) : "0:00"; color: "#7d7a96"; font.pixelSize: 11; font.family: "CaskaydiaCove Nerd Font" }
                    Text { anchors.right: parent.right; anchors.bottom: parent.bottom; text: root.player ? root.fmt(root.player.length) : "0:00"; color: "#7d7a96"; font.pixelSize: 11; font.family: "CaskaydiaCove Nerd Font" }
                }

                // controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18
                    Rectangle {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 22
                        color: prevArea.containsMouse ? "#30a77bff" : "transparent"
                        Text { anchors.centerIn: parent; text: "\uf048"; color: "#d9d4ee"; font.pixelSize: 18; font.family: "CaskaydiaCove Nerd Font" }
                        MouseArea { id: prevArea; anchors.fill: parent; hoverEnabled: true; onClicked: if (root.player) root.player.previous() }
                    }
                    Rectangle {
                        Layout.preferredWidth: 56; Layout.preferredHeight: 56; radius: 28
                        color: playArea.containsMouse ? "#c0a0ff" : "#a77bff"
                        Text { anchors.centerIn: parent; text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"; color: "#0e0c16"; font.pixelSize: 22; font.family: "CaskaydiaCove Nerd Font" }
                        MouseArea { id: playArea; anchors.fill: parent; hoverEnabled: true; onClicked: if (root.player) root.player.togglePlaying() }
                    }
                    Rectangle {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 22
                        color: nextArea.containsMouse ? "#30a77bff" : "transparent"
                        Text { anchors.centerIn: parent; text: "\uf051"; color: "#d9d4ee"; font.pixelSize: 18; font.family: "CaskaydiaCove Nerd Font" }
                        MouseArea { id: nextArea; anchors.fill: parent; hoverEnabled: true; onClicked: if (root.player) root.player.next() }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
