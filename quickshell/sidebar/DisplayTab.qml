import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: t
    property var sh
    property bool active: false
    readonly property var o: dp.res
    readonly property string nerd: sh.nerd
    readonly property int count: o ? o.filter(function(x) { return x.on }).length : 0

    Poller { id: dp; command: [t.sh.scripts + "qs-display.py"]; interval: 3000; active: t.active }
    Timer { id: refT; interval: 1200; onTriggered: dp.refresh() }
    function ni(args) { Quickshell.execDetached(["niri", "msg", "output"].concat(args)); refT.restart() }
    function place(b, side) {
        var a = o[0]
        var x = a.x, y = a.y
        if (side === "right") x = a.x + a.w
        else if (side === "left") x = a.x - b.w
        else if (side === "above") y = a.y - b.h
        else y = a.y + a.h
        ni([b.name, "position", "set", String(x), String(y)])
    }

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

            SecLabel { text: "PROJECTOR / 2ND DISPLAY" }
            Rectangle {
                width: parent.width; radius: 16; color: "#12ffffff"
                height: t.o && t.o.length > 1 ? 130 : 78
                Column { anchors.fill: parent; anchors.margins: 12; spacing: 8
                    Text { visible: !t.o || t.o.length < 2; width: parent.width; wrapMode: Text.WordWrap
                        text: "No second display detected. Plug in a projector or monitor and the modes show up here."; color: "#8a86a6"; font.pixelSize: 12; font.family: t.nerd }
                    Flow { visible: t.o && t.o.length > 1; spacing: 8; width: parent.width
                        Chip { text: "Extend"; icon: ""; onClicked: Quickshell.execDetached([t.sh.scripts + "display-mode.sh", "extend"]) }
                        Chip { text: "Mirror"; icon: ""; onClicked: Quickshell.execDetached([t.sh.scripts + "display-mode.sh", "mirror"]) }
                        Chip { text: "Laptop only"; icon: ""; onClicked: Quickshell.execDetached([t.sh.scripts + "display-mode.sh", "laptop"]) }
                        Chip { text: "External only"; icon: ""; onClicked: Quickshell.execDetached([t.sh.scripts + "display-mode.sh", "external"]) }
                    }
                    Text { visible: t.o && t.o.length > 1; width: parent.width; wrapMode: Text.WordWrap
                        text: "Mirroring needs the wl-mirror package (niri cannot do it on its own)."; color: "#8a86a6"; font.pixelSize: 10; font.family: t.nerd }
                }
            }

            Repeater {
                model: t.o ? t.o : []
                delegate: Column {
                    id: oc
                    required property var modelData
                    required property int index
                    width: col.width
                    spacing: 8
                    SecLabel { text: oc.modelData.name.toUpperCase() + (oc.modelData.on ? "" : "  ·  AUS") }
                    Rectangle {
                        width: parent.width; radius: 16; color: "#12ffffff"
                        height: inner.implicitHeight + 24
                        Column { id: inner; x: 12; y: 12; width: parent.width - 24; spacing: 10
                            Text { text: oc.modelData.model + (oc.modelData.on ? "  ·  " + oc.modelData.w + "×" + oc.modelData.h : ""); width: parent.width; elide: Text.ElideRight; color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd }
                            Text { text: "Resolution / refresh rate"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                            Flow { spacing: 6; width: parent.width
                                Repeater { model: oc.modelData.modes
                                    delegate: Chip { required property var modelData; text: modelData.label; fs: 11; pad: 9; active: modelData.cur
                                        onClicked: t.ni([oc.modelData.name, "mode", modelData.s]) } } }
                            Text { text: "Scale"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                            Flow { spacing: 6; width: parent.width
                                Repeater { model: [1, 1.25, 1.5, 1.75, 2]
                                    delegate: Chip { required property var modelData; text: modelData + "×"; fs: 11; pad: 9; active: Math.abs(oc.modelData.scale - modelData) < 0.01
                                        onClicked: t.ni([oc.modelData.name, "scale", String(modelData)]) } } }
                            Text { text: "Rotation"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                            Flow { spacing: 6; width: parent.width
                                Repeater { model: [ { l: "0°", v: "normal", k: "Normal" }, { l: "90°", v: "90", k: "_90" }, { l: "180°", v: "180", k: "_180" }, { l: "270°", v: "270", k: "_270" } ]
                                    delegate: Chip { required property var modelData; text: modelData.l; fs: 11; pad: 9; active: oc.modelData.transform === modelData.k
                                        onClicked: t.ni([oc.modelData.name, "transform", modelData.v]) } } }
                            Text { visible: oc.index > 0; text: "Position relative to display 1"; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                            Flow { visible: oc.index > 0; spacing: 6; width: parent.width
                                Chip { text: "right"; fs: 11; pad: 9; onClicked: t.place(oc.modelData, "right") }
                                Chip { text: "left"; fs: 11; pad: 9; onClicked: t.place(oc.modelData, "left") }
                                Chip { text: "above"; fs: 11; pad: 9; onClicked: t.place(oc.modelData, "above") }
                                Chip { text: "below"; fs: 11; pad: 9; onClicked: t.place(oc.modelData, "below") }
                            }
                            Chip { visible: t.o.length > 1 && (oc.index > 0 || t.count > 1); text: oc.modelData.on ? "Turn off" : "Turn on"; icon: ""; accent: "#e0607a"
                                onClicked: t.ni([oc.modelData.name, oc.modelData.on ? "off" : "on"]) }
                        }
                    }
                }
            }
            Text { width: parent.width; wrapMode: Text.WordWrap; leftPadding: 2
                text: "Note: changing the scale also changes the size of this sidebar."; color: "#8a86a6"; font.pixelSize: 10; font.family: t.nerd }
        }
    }
    ScrollHint { target: fl; active: t.active }
}
