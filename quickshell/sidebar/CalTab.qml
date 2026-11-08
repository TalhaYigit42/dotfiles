import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: t
    property var sh
    property bool active: false
    readonly property string nerd: sh.nerd
    readonly property var ev: ep.res ? ep.res : []
    readonly property var nt: np.res
    property int yy: new Date().getFullYear()
    property int mm: new Date().getMonth()
    property string sel: Qt.formatDate(new Date(), "yyyy-MM-dd")
    readonly property string todayS: Qt.formatDate(new Date(), "yyyy-MM-dd")
    readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    Poller { id: ep; command: [t.sh.scripts + "qs-events.py"]; interval: 20000; active: t.active }
    Poller { id: np; command: ["sh", "-c", "echo \"{\\\"n\\\": $(swaync-client -c 2>/dev/null || echo 0), \\\"dnd\\\": $(swaync-client -D 2>/dev/null || echo false)}\""]; interval: 3000; active: t.active }
    function ds(d) { return d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2) }
    function cell(i) {
        var first = new Date(yy, mm, 1), off = (first.getDay() + 6) % 7
        return new Date(yy, mm, 1 - off + i)
    }
    function hasEv(s) { for (var i = 0; i < ev.length; i++) if (ev[i].date === s) return true; return false }
    function shift(n) { var d = new Date(yy, mm + n, 1); yy = d.getFullYear(); mm = d.getMonth() }
    function goToday() { var d = new Date(); yy = d.getFullYear(); mm = d.getMonth(); sel = todayS }
    function dayEvents() { var r = []; for (var i = 0; i < ev.length; i++) if (ev[i].date === sel) r.push(ev[i]); return r }
    function upcoming() { var r = []; for (var i = 0; i < ev.length && r.length < 5; i++) if (ev[i].date > sel) r.push(ev[i]); return r }
    function nice(s) { return s.slice(8, 10) + "." + s.slice(5, 7) + "." }

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

            Rectangle {
                width: parent.width; height: 384; radius: 18; color: "#12ffffff"
                Column { anchors.fill: parent; anchors.margins: 12; spacing: 8
                    Row { width: parent.width; height: 34
                        Chip { text: ""; icon: ""; pad: 6; onClicked: t.shift(-1) }
                        Text { text: t.months[t.mm] + " " + t.yy; width: parent.width - 172; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter
                            color: "#ffffff"; font.pixelSize: 15; font.bold: true; font.family: t.nerd }
                        Chip { text: ""; icon: ""; pad: 6; onClicked: t.shift(1) }
                        Chip { text: "today"; fs: 11; pad: 9; onClicked: t.goToday() }
                    }
                    Row { width: parent.width
                        Repeater { model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            delegate: Text { required property string modelData; width: parent.width / 7; horizontalAlignment: Text.AlignHCenter; text: modelData; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd } }
                    }
                    Grid { columns: 7; width: parent.width; rowSpacing: 4
                        Repeater { model: 42
                            delegate: Rectangle {
                                required property int index
                                readonly property date d: t.cell(index)
                                readonly property string s: t.ds(d)
                                readonly property bool inM: d.getMonth() === t.mm
                                width: (col.width - 24) / 7; height: 44; radius: 12
                                color: s === t.sel ? "#66a77bff" : (s === t.todayS ? "#2a8fe07a" : (cA.containsMouse ? "#22ffffff" : "transparent"))
                                border.width: s === t.todayS ? 1 : 0; border.color: "#8fe07a"
                                Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -3; text: d.getDate(); color: inM ? "#ffffff" : "#4f4b68"; font.pixelSize: 13; font.bold: s === t.todayS; font.family: t.nerd }
                                Rectangle { visible: t.hasEv(s); anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 5; width: 5; height: 5; radius: 3; color: "#e8c872" }
                                MouseArea { id: cA; anchors.fill: parent; hoverEnabled: true; onClicked: { t.sel = s; if (!inM) { t.yy = d.getFullYear(); t.mm = d.getMonth() } } }
                            } }
                    }
                }
            }

            SecLabel { text: "EVENTS · " + t.nice(t.sel) }
            Repeater {
                model: t.dayEvents()
                delegate: Rectangle { required property var modelData; width: col.width; height: 44; radius: 14; color: "#14e8c872"
                    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: (modelData.time !== "" ? modelData.time + "   " : "") + modelData.title; width: col.width - 28; elide: Text.ElideRight; color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd } }
            }
            Text { visible: t.dayEvents().length === 0; text: "No events on this day."; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd; leftPadding: 4 }
            Repeater {
                model: t.upcoming()
                delegate: Rectangle { required property var modelData; width: col.width; height: 40; radius: 12; color: "#10ffffff"
                    Row { x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        Text { text: t.nice(modelData.date); color: "#b896ff"; font.pixelSize: 12; font.bold: true; font.family: t.nerd }
                        Text { text: (modelData.time !== "" ? modelData.time + " " : "") + modelData.title; width: col.width - 100; elide: Text.ElideRight; color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd } }
                }
            }
            Chip { text: "Add event"; icon: ""; onClicked: { Quickshell.execDetached([t.sh.scripts + "event-add.sh"]); t.sh.open = false } }

            SecLabel { text: "NOTIFICATIONS" }
            Rectangle { width: parent.width; height: 118; radius: 16; color: "#12ffffff"
                Column { anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Row { spacing: 12
                        Text { text: t.nt && t.nt.dnd ? "" : ""; color: t.nt && t.nt.n > 0 ? "#a77bff" : "#8a86a6"; font.pixelSize: 24; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                        Column { anchors.verticalCenter: parent.verticalCenter
                            Text { text: t.nt ? (t.nt.n === 0 ? "No new notifications" : t.nt.n + " notification" + (t.nt.n > 1 ? "s" : "")) : "…"; color: "#ffffff"; font.pixelSize: 14; font.bold: true; font.family: t.nerd }
                            Text { text: t.nt && t.nt.dnd ? "Do not disturb is on" : "Notifications on"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                        }
                    }
                    Flow { spacing: 6; width: parent.width
                        Chip { text: "History"; icon: ""; fs: 11; pad: 9; onClicked: { Quickshell.execDetached(["swaync-client", "-t", "-sw"]); t.sh.open = false } }
                        Chip { text: "Clear"; icon: ""; fs: 11; pad: 9; onClicked: { Quickshell.execDetached(["swaync-client", "-C"]); np.refresh() } }
                        Chip { text: "Quiet"; icon: ""; fs: 11; pad: 9; active: t.nt ? t.nt.dnd : false; onClicked: { Quickshell.execDetached(["swaync-client", "-d", "-sw"]); np.refresh() } }
                    }
                }
            }
        }
    }
    ScrollHint { target: fl; active: t.active }
}
