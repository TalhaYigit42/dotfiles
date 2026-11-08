import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: t
    property var sh
    property bool active: false
    readonly property var n: np.res
    readonly property var pg: pp.res
    readonly property string nerd: sh.nerd
    property real rxRate: 0
    property real txRate: 0
    property real lastRx: -1
    property real lastTx: 0
    property real lastT: 0

    Poller { id: np; command: [t.sh.scripts + "qs-net.py"]; interval: 4000; active: t.active }
    Poller { id: pp; command: [t.sh.scripts + "qs-ping.py"]; interval: 9000; active: t.active }
    Timer { id: refT; interval: 1800; onTriggered: np.refresh() }

    Connections { target: np
        function onResChanged() {
            var d = np.res, now = Date.now()
            if (d && t.lastRx >= 0 && now > t.lastT) { t.rxRate = Math.max(0, (d.rx - t.lastRx) * 1000 / (now - t.lastT)); t.txRate = Math.max(0, (d.tx - t.lastTx) * 1000 / (now - t.lastT)) }
            if (d) { t.lastRx = d.rx; t.lastTx = d.tx; t.lastT = now }
        } }

    function rate(b) { return b >= 1e6 ? (b / 1e6).toFixed(1) + " MB/s" : (b >= 1e3 ? Math.round(b / 1e3) + " KB/s" : Math.round(b) + " B/s") }
    function qcol(s) { return s >= 65 ? "#8fe07a" : (s >= 40 ? "#e8c872" : "#e0607a") }
    function pingText(p) {
        if (!p || p.ms === null) return { t: "no reply", c: "#e0607a" }
        var q = p.loss > 5 ? "unstable" : (p.ms < 60 ? "very good" : (p.ms < 120 ? "good" : (p.ms < 250 ? "fair" : "poor")))
        return { t: Math.round(p.ms) + " ms · " + q, c: p.loss > 5 || p.ms >= 250 ? "#e0607a" : (p.ms >= 120 ? "#e8c872" : "#8fe07a") }
    }
    readonly property var inet: pingText(pg ? pg.net : null)
    readonly property var gwp: pingText(pg ? pg.gw : null)
    readonly property var cur: { if (!n) return null; for (var i = 0; i < n.wifi.length; i++) if (n.wifi[i].inuse) return n.wifi[i]; return null }

    Flickable {
        id: fl
        anchors.fill: parent
        anchors.rightMargin: 8
        contentHeight: col.implicitHeight + 8
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: col
            width: fl.width
            spacing: 8

            SecLabel { text: "CONNECTION" }
            Rectangle {
                width: parent.width; height: 238; radius: 18; color: "#16a77bff"; border.width: 1; border.color: "#40a77bff"
                Column { anchors.fill: parent; anchors.margins: 14; spacing: 7
                    Row { spacing: 10
                        Text { text: t.cur ? "" : (t.n && t.n.dev !== "" ? "" : ""); color: t.cur ? t.qcol(t.cur.signal) : "#e0607a"; font.pixelSize: 24; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                        Column { anchors.verticalCenter: parent.verticalCenter
                            Text { text: t.cur ? t.cur.ssid : (t.n && t.n.dev !== "" ? "Wired / " + t.n.dev : "No network"); color: "#ffffff"; font.pixelSize: 16; font.bold: true; font.family: t.nerd; width: col.width - 90; elide: Text.ElideRight }
                            Text { text: t.inet.t; color: t.inet.c; font.pixelSize: 12; font.family: t.nerd }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: "#26ffffff" }
                    Grid { columns: 2; columnSpacing: 12; rowSpacing: 6; width: parent.width
                        Text { text: "Signal"; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: t.cur ? t.cur.signal + " %" : "—"; color: t.cur ? t.qcol(t.cur.signal) : "#8a86a6"; font.pixelSize: 12; font.bold: true; font.family: t.nerd }
                        Text { text: "Latency (internet)"; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: t.pg && t.pg.net.ms !== null ? Math.round(t.pg.net.ms) + " ms · " + t.pg.net.loss + " % loss" : "…"; color: t.inet.c; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: "Latency (router)"; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: t.pg && t.pg.gw.ms !== null ? Math.round(t.pg.gw.ms) + " ms · " + t.pg.gw.loss + " % loss" : "…"; color: t.gwp.c; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: "Speed ↓ / ↑"; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: t.rate(t.rxRate) + "  /  " + t.rate(t.txRate); color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: "Link rate"; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: t.cur ? t.cur.rate : "—"; color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: "IP address"; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: t.n && t.n.ip !== "" ? t.n.ip.split("/")[0] : "—"; color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: "Router"; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                        Text { text: t.n && t.n.gw !== "" ? t.n.gw : "—"; color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd }
                    }
                }
            }

            SecLabel { text: "ACTIVE CONNECTIONS" }
            Repeater {
                model: t.n ? t.n.active : []
                delegate: Rectangle {
                    required property var modelData
                    width: col.width; height: 44; radius: 14; color: "#10ffffff"
                    Row { anchors.verticalCenter: parent.verticalCenter; x: 14; spacing: 12
                        Text { text: modelData.type === "wifi" ? "" : (modelData.type === "ethernet" ? "" : ""); color: "#b896ff"; font.pixelSize: 16; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                        Column { anchors.verticalCenter: parent.verticalCenter
                            Text { text: modelData.name; width: col.width - 70; elide: Text.ElideRight; color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd }
                            Text { text: modelData.type + " · " + modelData.dev; color: "#8a86a6"; font.pixelSize: 10; font.family: t.nerd }
                        }
                    }
                }
            }

            SecLabel { text: "AVAILABLE NETWORKS" }
            Repeater {
                model: t.n ? t.n.wifi : []
                delegate: Rectangle {
                    required property var modelData
                    width: col.width; height: 54; radius: 14
                    color: modelData.inuse ? "#26a77bff" : (wA.containsMouse ? "#22ffffff" : "#10ffffff")
                    border.width: modelData.inuse ? 1 : 0; border.color: "#60a77bff"
                    Row { x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        Row { spacing: 2; anchors.verticalCenter: parent.verticalCenter
                            Repeater { model: 4
                                delegate: Rectangle { required property int index; width: 4; height: 6 + index * 4; anchors.bottom: parent.bottom; radius: 1
                                    color: modelData.signal >= (index + 1) * 24 - 10 ? t.qcol(modelData.signal) : "#33ffffff" } }
                        }
                        Column { anchors.verticalCenter: parent.verticalCenter
                            Text { text: modelData.ssid; width: col.width - 120; elide: Text.ElideRight; color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd }
                            Text { text: modelData.signal + " % · " + modelData.sec + " · " + modelData.rate; color: "#8a86a6"; font.pixelSize: 10; font.family: t.nerd }
                        }
                    }
                    Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                        text: modelData.inuse ? "" : (modelData.sec === "open" ? "" : ""); color: modelData.inuse ? "#8fe07a" : "#8a86a6"; font.pixelSize: 14; font.family: t.nerd }
                    MouseArea { id: wA; anchors.fill: parent; hoverEnabled: true; enabled: !modelData.inuse
                        onClicked: { Quickshell.execDetached([t.sh.scripts + "wifi-connect.sh", modelData.ssid]); t.sh.open = false } }
                }
            }
            Row { spacing: 8
                Chip { text: "Rescan"; icon: ""; onClicked: { Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]); refT.restart() } }
                Chip { text: "Settings"; icon: ""; onClicked: { Quickshell.execDetached(["nm-connection-editor"]); t.sh.open = false } }
            }
        }
    }
    ScrollHint { target: fl; active: t.active }
}
