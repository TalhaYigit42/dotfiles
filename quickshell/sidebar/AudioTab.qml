import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: t
    property var sh
    property bool active: false
    readonly property var d: ap.res
    readonly property string nerd: sh.nerd
    property var pend: []

    Poller { id: ap; command: [t.sh.scripts + "qs-audio.py"]; interval: 2000; active: t.active }
    Timer { id: sendT; interval: 90; onTriggered: { Quickshell.execDetached(t.pend); refT.restart() } }
    Timer { id: refT; interval: 500; onTriggered: ap.refresh() }
    function send(cmd) { pend = cmd; sendT.restart() }
    function act(cmd) { Quickshell.execDetached(cmd); refT.restart() }
    function short(s) { return s.replace("400 Series Chipset Family On-Package HD Audio ", "").replace(" (Stereo)", "") }

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

            SecLabel { text: "OUTPUT" }
            Repeater {
                model: t.d ? t.d.sinks : []
                delegate: Rectangle {
                    required property var modelData
                    width: col.width; height: modelData.default ? 96 : 46; radius: 14
                    color: modelData.default ? "#26a77bff" : (sA.containsMouse ? "#22ffffff" : "#10ffffff")
                    border.width: modelData.default ? 1 : 0; border.color: "#60a77bff"
                    Behavior on height { NumberAnimation { duration: 120 } }
                    MouseArea { id: sA; anchors.fill: parent; hoverEnabled: true; enabled: !modelData.default
                        onClicked: t.act(["pactl", "set-default-sink", modelData.name]) }
                    Row { x: 14; y: 13; spacing: 10; height: 20
                        Text { text: modelData.default ? "" : ""; color: modelData.default ? "#8fe07a" : "#8a86a6"; font.pixelSize: 13; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: t.short(modelData.desc); width: col.width - 70; elide: Text.ElideRight; color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row { visible: modelData.default; x: 14; y: 50; width: parent.width - 28; spacing: 10
                        Chip { text: ""; icon: modelData.mute ? "" : ""; active: modelData.mute; accent: "#e0607a"; pad: 4; onClicked: t.act(["pactl", "set-sink-mute", modelData.name, "toggle"]) }
                        MiniSlider { width: parent.width - 100; anchors.verticalCenter: parent.verticalCenter; value: modelData.vol / 100; fill: modelData.mute ? "#7d7a96" : "#a77bff"
                            onMoved: function(v) { t.send(["pactl", "set-sink-volume", modelData.name, Math.round(v * 100) + "%"]) } }
                        Text { text: modelData.vol + "%"; color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd; width: 40; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            SecLabel { text: "INPUT" }
            Repeater {
                model: t.d ? t.d.sources : []
                delegate: Rectangle {
                    required property var modelData
                    width: col.width; height: modelData.default ? 96 : 46; radius: 14
                    color: modelData.default ? "#26a77bff" : (iA.containsMouse ? "#22ffffff" : "#10ffffff")
                    border.width: modelData.default ? 1 : 0; border.color: "#60a77bff"
                    Behavior on height { NumberAnimation { duration: 120 } }
                    MouseArea { id: iA; anchors.fill: parent; hoverEnabled: true; enabled: !modelData.default
                        onClicked: t.act(["pactl", "set-default-source", modelData.name]) }
                    Row { x: 14; y: 13; spacing: 10; height: 20
                        Text { text: modelData.default ? "" : ""; color: modelData.default ? "#8fe07a" : "#8a86a6"; font.pixelSize: 13; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: t.short(modelData.desc); width: col.width - 70; elide: Text.ElideRight; color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row { visible: modelData.default; x: 14; y: 50; width: parent.width - 28; spacing: 10
                        Chip { text: ""; icon: modelData.mute ? "" : ""; active: modelData.mute; accent: "#e0607a"; pad: 4; onClicked: t.act(["pactl", "set-source-mute", modelData.name, "toggle"]) }
                        MiniSlider { width: parent.width - 100; anchors.verticalCenter: parent.verticalCenter; value: modelData.vol / 100; fill: modelData.mute ? "#7d7a96" : "#8fe07a"
                            onMoved: function(v) { t.send(["pactl", "set-source-volume", modelData.name, Math.round(v * 100) + "%"]) } }
                        Text { text: modelData.vol + "%"; color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd; width: 40; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            SecLabel { text: "APPS" }
            Repeater {
                model: t.d ? t.d.apps : []
                delegate: Rectangle {
                    required property var modelData
                    width: col.width; height: 78; radius: 14; color: "#10ffffff"
                    Text { x: 14; y: 11; text: modelData.name; color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd }
                    Row { x: 14; y: 38; width: parent.width - 28; spacing: 10
                        Chip { text: ""; icon: modelData.mute ? "" : ""; active: modelData.mute; accent: "#e0607a"; pad: 4; onClicked: t.act(["pactl", "set-sink-input-mute", String(modelData.id), "toggle"]) }
                        MiniSlider { width: parent.width - 100; anchors.verticalCenter: parent.verticalCenter; value: modelData.vol / 100; fill: "#a77bff"
                            onMoved: function(v) { t.send(["pactl", "set-sink-input-volume", String(modelData.id), Math.round(v * 100) + "%"]) } }
                        Text { text: modelData.vol + "%"; color: "#e6e2f7"; font.pixelSize: 12; font.family: t.nerd; width: 40; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
            Text { visible: t.d && t.d.apps.length === 0; text: "No app is playing sound."; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd; leftPadding: 4 }

            Chip { text: "Sound mixer (pavucontrol)"; icon: ""; onClicked: { Quickshell.execDetached(["pavucontrol"]); t.sh.open = false } }
        }
    }
    ScrollHint { target: fl; active: t.active }
}
