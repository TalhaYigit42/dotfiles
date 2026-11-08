import QtQuick

// horizontal slider: value 0..1; shows its own position while you drag; emits moved(v)
Item {
    id: s
    property real value: 0
    property color fill: "#a77bff"
    property real dragV: 0
    readonly property bool dragging: ma.pressed
    readonly property real shown: Math.max(0, Math.min(1, ma.pressed ? dragV : value))
    signal moved(real v)
    implicitHeight: 24

    Rectangle { id: track; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: "#3d3a52" }
    Rectangle { anchors.left: track.left; anchors.verticalCenter: track.verticalCenter; height: 6; radius: 3; width: track.width * s.shown; color: s.fill }
    Rectangle { x: Math.max(0, Math.min(track.width - 14, track.width * s.shown - 7)); anchors.verticalCenter: track.verticalCenter; width: 14; height: 14; radius: 7; color: "#ffffff" }
    MouseArea {
        id: ma
        anchors.fill: parent
        onPressed: function(m) { s.dragV = Math.max(0, Math.min(1, m.x / width)); s.moved(s.dragV) }
        onPositionChanged: function(m) { if (pressed) { s.dragV = Math.max(0, Math.min(1, m.x / width)); s.moved(s.dragV) } }
    }
}
