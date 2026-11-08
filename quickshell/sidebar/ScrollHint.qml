import QtQuick

// thin purple bar on the right edge that shows where you are in a scrollable list
Rectangle {
    id: h
    property Flickable target
    property bool active: true
    visible: active && target !== null && target.visibleArea.heightRatio < 0.995
    anchors.right: parent.right
    anchors.rightMargin: 1
    width: 3; radius: 2
    color: "#80a77bff"
    y: target ? target.visibleArea.yPosition * parent.height : 0
    height: target ? Math.max(28, target.visibleArea.heightRatio * parent.height) : 0
}
