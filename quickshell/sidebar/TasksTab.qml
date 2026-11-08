import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: t
    property var sh
    property bool active: false
    readonly property string nerd: sh.nerd
    property var cpuH: []
    property var ramH: []
    property var rxH: []
    property var txH: []
    property var cur: null
    readonly property var info: ip.res
    readonly property var procs: pp.res
    readonly property real netMax: { var m = 1e5; for (var i = 0; i < rxH.length; i++) m = Math.max(m, rxH[i], txH[i]); return m * 1.15 }

    Poller { id: ip; command: [t.sh.scripts + "qs-info.py"]; interval: 60000; active: t.active }
    Poller { id: pp; command: [t.sh.scripts + "qs-procs.py"]; interval: 2500; active: t.active }

    Process {
        id: stat
        command: [t.sh.scripts + "qs-stat.py"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line)
                    t.cur = d
                    function push(a, v) { var r = a.concat([v]); return r.length > 60 ? r.slice(r.length - 60) : r }
                    t.cpuH = push(t.cpuH, d.cpu); t.ramH = push(t.ramH, d.ram); t.rxH = push(t.rxH, d.rx); t.txH = push(t.txH, d.tx)
                } catch (e) { }
            }
        }
    }

    function rate(b) { return b >= 1e6 ? (b / 1e6).toFixed(1) + " MB/s" : (b >= 1e3 ? Math.round(b / 1e3) + " KB/s" : Math.round(b) + " B/s") }

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

            // CPU
            Rectangle { width: parent.width; height: 118; radius: 16; color: "#12ffffff"
                Column { anchors.fill: parent; anchors.margins: 12; spacing: 6
                    Row { width: parent.width
                        Text { text: "  CPU"; color: "#b896ff"; font.pixelSize: 12; font.bold: true; font.family: t.nerd; width: 80 }
                        Text { text: t.cur ? t.cur.cpu.toFixed(0) + " %" : "…"; color: "#ffffff"; font.pixelSize: 14; font.bold: true; font.family: t.nerd; width: parent.width - 80 - 70 }
                        Text { text: t.cur ? t.cur.temp + " °C" : ""; color: t.cur && t.cur.temp >= 80 ? "#e0607a" : "#8a86a6"; font.pixelSize: 12; font.family: t.nerd; horizontalAlignment: Text.AlignRight; width: 70 }
                    }
                    Graph { width: parent.width; height: 70; values: t.cpuH; maxV: 100; line: "#a77bff" }
                }
            }
            // RAM
            Rectangle { width: parent.width; height: 118; radius: 16; color: "#12ffffff"
                Column { anchors.fill: parent; anchors.margins: 12; spacing: 6
                    Row { width: parent.width
                        Text { text: "  RAM"; color: "#8fe07a"; font.pixelSize: 12; font.bold: true; font.family: t.nerd; width: 80 }
                        Text { text: t.cur ? t.cur.ram.toFixed(0) + " %" : "…"; color: "#ffffff"; font.pixelSize: 14; font.bold: true; font.family: t.nerd; width: parent.width - 80 - 110 }
                        Text { text: t.cur ? t.cur.ram_used.toFixed(1) + " / " + t.cur.ram_total.toFixed(1) + " GB" : ""; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd; horizontalAlignment: Text.AlignRight; width: 110 }
                    }
                    Graph { width: parent.width; height: 70; values: t.ramH; maxV: 100; line: "#8fe07a" }
                }
            }
            // NET
            Rectangle { width: parent.width; height: 132; radius: 16; color: "#12ffffff"
                Column { anchors.fill: parent; anchors.margins: 12; spacing: 6
                    Row { width: parent.width; spacing: 6
                        Text { text: "  Network"; color: "#7ad6d0"; font.pixelSize: 12; font.bold: true; font.family: t.nerd; width: 70 }
                        Text { text: "↓ " + (t.cur ? t.rate(t.cur.rx) : "…"); color: "#7ad6d0"; font.pixelSize: 12; font.family: t.nerd; width: (parent.width - 82) / 2 }
                        Text { text: "↑ " + (t.cur ? t.rate(t.cur.tx) : "…"); color: "#e0a0c8"; font.pixelSize: 12; font.family: t.nerd }
                    }
                    Item { width: parent.width; height: 84
                        Graph { anchors.fill: parent; values: t.rxH; maxV: t.netMax; line: "#7ad6d0" }
                        Graph { anchors.fill: parent; values: t.txH; maxV: t.netMax; line: "#e0a0c8"; grid: false }
                    }
                }
            }

            SecLabel { text: "SPECS" }
            Rectangle { width: parent.width; height: specs.implicitHeight + 24; radius: 16; color: "#12ffffff"
                Grid { id: specs; x: 12; y: 12; width: parent.width - 24; columns: 1; rowSpacing: 5
                    Repeater {
                        model: t.info ? [["CPU", t.info.cpu + " (" + t.info.cores + " Threads)"], ["GPU", t.info.gpu], ["RAM", t.info.ram], ["Disk", t.info.disk + " (" + t.info.disk_pct + " %)"],
                                         ["Kernel", t.info.kernel], ["Uptime", t.info.uptime]] : []
                        delegate: Item { required property var modelData; width: specs.width; height: lbl.implicitHeight + 2
                            Text { text: modelData[0]; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd; width: 64 }
                            Text { id: lbl; x: 70; text: modelData[1]; color: "#e6e2f7"; font.pixelSize: 11; font.family: t.nerd; width: parent.width - 70; wrapMode: Text.WordWrap } }
                    }
                }
            }

            SecLabel { text: "PROCESSES" }
            Repeater {
                model: t.procs ? t.procs : []
                delegate: Rectangle {
                    required property var modelData
                    width: col.width; height: 40; radius: 12; color: pA.containsMouse ? "#22ffffff" : "#10ffffff"
                    MouseArea { id: pA; anchors.fill: parent; hoverEnabled: true }
                    Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; width: col.width - 190; elide: Text.ElideRight; color: "#ffffff"; font.pixelSize: 12; font.family: t.nerd }
                    Text { x: col.width - 176; anchors.verticalCenter: parent.verticalCenter; text: modelData.cpu.toFixed(0) + " %"; color: modelData.cpu >= 40 ? "#e0607a" : "#b896ff"; font.pixelSize: 12; font.bold: true; font.family: t.nerd; width: 46; horizontalAlignment: Text.AlignRight }
                    Text { x: col.width - 124; anchors.verticalCenter: parent.verticalCenter; text: modelData.mb + " MB"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd; width: 70; horizontalAlignment: Text.AlignRight }
                    Rectangle { x: col.width - 44; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 28; radius: 9; color: kA.containsMouse ? "#55e0607a" : "transparent"
                        Text { anchors.centerIn: parent; text: ""; color: "#e0607a"; font.pixelSize: 13; font.family: t.nerd }
                        MouseArea { id: kA; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["kill", String(modelData.pid)]) } }
                }
            }
            Chip { text: "Open btop"; icon: ""; onClicked: { Quickshell.execDetached(["kitty", "--class", "btop", "-e", "btop"]); t.sh.open = false } }
        }
    }
    ScrollHint { target: fl; active: t.active }
}
