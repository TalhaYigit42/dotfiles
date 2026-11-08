import QtQuick

Rectangle {
    id: c
    property string text: ""
    property string icon: ""
    property bool active: false
    property int pad: 12
    property int fs: 12
    property color accent: "#a77bff"
    signal clicked()
    implicitHeight: 32
    implicitWidth: lbl.implicitWidth + pad * 2 + (icon !== "" ? 22 : 0)
    radius: 10
    color: active ? Qt.rgba(accent.r, accent.g, accent.b, 0.35) : (ma.containsMouse ? "#26ffffff" : "#14ffffff")
    border.width: active ? 1 : 0
    border.color: accent
    Row {
        anchors.centerIn: parent
        spacing: 6
        Text { visible: c.icon !== ""; text: c.icon; color: c.active ? "#ffffff" : c.accent; font.pixelSize: c.fs + 3; font.family: "CaskaydiaCove Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
        Text { id: lbl; text: c.text; color: c.active ? "#ffffff" : "#e6e2f7"; font.pixelSize: c.fs; font.family: "CaskaydiaCove Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: c.clicked() }
}
