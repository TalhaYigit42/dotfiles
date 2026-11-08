import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: t
    property var sh
    property bool active: false
    readonly property var h: hp.res
    readonly property var w: wp.res
    property real vv: 0
    property real bv: 0
    property date now: new Date()
    readonly property var wd: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var mn: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property string nerd: sh.nerd

    Poller { id: hp; command: [t.sh.scripts + "qs-home.py"]; interval: 3000; active: t.active }
    Poller { id: wp; command: [t.sh.scripts + "qs-weather.py"]; interval: 600000; active: t.active }
    Poller { id: ep; command: [t.sh.scripts + "qs-events.py"]; interval: 30000; active: t.active }
    Timer { interval: 15000; running: t.active; repeat: true; onTriggered: t.now = new Date() }
    onActiveChanged: if (active) now = new Date()

    Connections { target: hp; function onResChanged() { if (hp.res && !volS.dragging) t.vv = hp.res.vol; if (hp.res && !briS.dragging) t.bv = hp.res.bri } }
    Timer { id: volT; interval: 90; onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", t.vv.toFixed(2)]) }
    Timer { id: briT; interval: 90; onTriggered: Quickshell.execDetached(["brightnessctl", "set", Math.max(5, Math.round(t.bv * 100)) + "%"]) }
    Timer { id: refT; interval: 700; onTriggered: hp.refresh() }
    function run(cmd, close) { Quickshell.execDetached(cmd); if (close) t.sh.open = false; else refT.restart() }

    readonly property var toggles: [
        { ic: "", n: "Wi-Fi",       on: h ? h.wifi_on : false, sub: h && h.wifi_on ? (h.ssid !== "" ? h.ssid : "not connected") : "off",
          cmd: ["nmcli", "radio", "wifi", h && h.wifi_on ? "off" : "on"] },
        { ic: "", n: "Bluetooth",  on: h ? h.bt_on : false, sub: h && h.bt_on ? (h.bt_devs.length > 0 ? h.bt_devs[0] : "on") : "off",
          cmd: ["bluetoothctl", "power", h && h.bt_on ? "off" : "on"] },
        { ic: "", n: "Quiet",       on: h ? h.dnd : false, sub: h && h.dnd ? "on" : "off", cmd: ["swaync-client", "-d", "-sw"] },
        { ic: "", n: "Night light", on: h ? h.night : false, sub: h && h.night ? "on" : "off", cmd: [t.sh.scripts + "nightlight.sh"] },
        { ic: "", n: "Navi",       on: h ? h.navi : false, sub: h && h.navi ? "awake" : "Standby", cmd: [t.sh.scripts + "navi.sh", "toggle"] },
        { ic: "", n: "Lock",    on: false, sub: "now", cmd: [t.sh.scripts + "lock.sh"], close: true }
    ]

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
            spacing: 10

            // date + weather
            Rectangle {
                width: parent.width; height: 92; radius: 18
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#33a77bff" } GradientStop { position: 1; color: "#14a77bff" } }
                Column { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text { text: t.wd[t.now.getDay()]; color: "#c0a0ff"; font.pixelSize: 13; font.family: t.nerd }
                    Text { text: t.now.getDate() + ". " + t.mn[t.now.getMonth()]; color: "#ffffff"; font.pixelSize: 24; font.bold: true; font.family: t.nerd }
                }
                Row { visible: t.w && !t.w.error; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                    Text { text: t.w && !t.w.error ? t.sh.wxIcon(t.w.code, t.w.day) : ""; color: "#e8d9ff"; font.pixelSize: 30; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: t.w && !t.w.error ? t.w.temp + "°" : ""; color: "#ffffff"; font.pixelSize: 28; font.bold: true; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // quick toggles
            Grid {
                columns: 3; spacing: 8; width: parent.width
                Repeater {
                    model: t.toggles
                    delegate: Rectangle {
                        required property var modelData
                        width: (col.width - 16) / 3; height: 76; radius: 16
                        color: modelData.on ? "#55a77bff" : (tgA.containsMouse ? "#22ffffff" : "#12ffffff")
                        border.width: modelData.on ? 1 : 0; border.color: "#a77bff"
                        Column { anchors.centerIn: parent; spacing: 3; width: parent.width - 10
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.ic; color: modelData.on ? "#ffffff" : "#b896ff"; font.pixelSize: 22; font.family: t.nerd }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.n; color: "#ffffff"; font.pixelSize: 12; font.family: t.nerd }
                            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.sub; elide: Text.ElideRight; color: modelData.on ? "#e0d4ff" : "#8a86a6"; font.pixelSize: 10; font.family: t.nerd }
                        }
                        MouseArea { id: tgA; anchors.fill: parent; hoverEnabled: true; onClicked: t.run(modelData.cmd, modelData.close === true) }
                    }
                }
            }

            // sliders
            Rectangle {
                width: parent.width; height: 118; radius: 16; color: "#12ffffff"
                Column { anchors.fill: parent; anchors.margins: 14; spacing: 6
                    Text { text: "   Volume  " + Math.round(t.vv * 100) + "%" + (t.h && t.h.muted ? "  (muted)" : ""); color: "#e6e2f7"; font.pixelSize: 13; font.family: t.nerd }
                    MiniSlider { id: volS; width: parent.width; value: t.vv; fill: t.h && t.h.muted ? "#7d7a96" : "#a77bff"
                        onMoved: function(v) { t.vv = v; volT.restart() } }
                    Text { text: "   Brightness  " + Math.round(t.bv * 100) + "%"; color: "#e6e2f7"; font.pixelSize: 13; font.family: t.nerd }
                    MiniSlider { id: briS; width: parent.width; value: t.bv; fill: "#8fe07a"
                        onMoved: function(v) { t.bv = v; briT.restart() } }
                }
            }

            // battery + wifi
            Rectangle {
                width: parent.width; height: 74; radius: 16; color: "#12ffffff"
                Row { anchors.fill: parent; anchors.margins: 14; spacing: 16
                    Column { width: (parent.width - 16) / 2; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text { text: "  Battery"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                        Text { text: t.h && t.h.bat >= 0 ? t.h.bat + "%" : "—"; color: t.h && t.h.bat < 20 ? "#e0607a" : "#8fe07a"; font.pixelSize: 22; font.bold: true; font.family: t.nerd }
                        Text { text: t.h ? (t.h.bat_status === "Charging" ? "charging" : (t.h.bat_status === "Full" ? "full" : "discharging")) : ""; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                    }
                    Column { width: (parent.width - 16) / 2; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text { text: "  Signal"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                        Text { text: t.h && t.h.ssid !== "" ? t.h.signal + "%" : "—"; color: t.h && t.h.signal >= 60 ? "#8fe07a" : (t.h && t.h.signal >= 35 ? "#e8c872" : "#e0607a"); font.pixelSize: 22; font.bold: true; font.family: t.nerd }
                        Text { width: parent.width; elide: Text.ElideRight; text: t.h ? t.h.ssid : ""; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                    }
                }
            }

            SecLabel { text: "UPCOMING" }
            Repeater {
                model: { var l = ep.res || [], r = [], td = Qt.formatDateTime(t.now, "yyyy-MM-dd"); for (var i = 0; i < l.length && r.length < 3; i++) if (l[i].date >= td) r.push(l[i]); return r }
                delegate: Rectangle {
                    required property var modelData
                    width: col.width; height: 46; radius: 14; color: "#12ffffff"
                    Row { anchors.verticalCenter: parent.verticalCenter; x: 14; spacing: 12
                        Text { text: modelData.date.slice(8, 10) + "." + modelData.date.slice(5, 7) + "."; color: "#b896ff"; font.pixelSize: 13; font.bold: true; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: (modelData.time !== "" ? modelData.time + "  " : "") + modelData.title; width: col.width - 100; elide: Text.ElideRight; color: "#e6e2f7"; font.pixelSize: 13; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
            Text { visible: !ep.res || ep.res.length === 0; width: parent.width; wrapMode: Text.WordWrap
                text: "No events. Add some in the calendar tab."; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
        }
    }
    ScrollHint { target: fl; active: t.active }
}
