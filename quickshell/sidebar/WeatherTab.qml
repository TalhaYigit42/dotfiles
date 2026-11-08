import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: t
    property var sh
    property bool active: false
    readonly property var w: wp.res
    readonly property string nerd: sh.nerd
    readonly property var dn: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    Poller { id: wp; command: [t.sh.scripts + "qs-weather.py"]; interval: 900000; active: t.active }
    function dayName(s, i) { return i === 0 ? "Today" : dn[new Date(s + "T12:00:00").getDay()] }

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

            Text { visible: !t.w; text: "loading …"; color: "#8a86a6"; font.pixelSize: 13; font.family: t.nerd }
            Text { visible: t.w && t.w.error !== undefined; width: parent.width; wrapMode: Text.WordWrap
                text: "Weather unavailable (no internet?)  " + (t.w && t.w.error ? t.w.error : ""); color: "#e0607a"; font.pixelSize: 12; font.family: t.nerd }

            Rectangle {
                visible: t.w && t.w.error === undefined
                width: parent.width; height: 172; radius: 20
                gradient: Gradient { GradientStop { position: 0; color: t.w && t.w.day ? "#44a77bff" : "#331a1740" } GradientStop { position: 1; color: "#14a77bff" } }
                Column { anchors.fill: parent; anchors.margins: 16; spacing: 4
                    Text { text: t.w && !t.w.error ? t.w.city : ""; color: "#d8c8ff"; font.pixelSize: 13; font.family: t.nerd }
                    Row { spacing: 14
                        Text { text: t.w && !t.w.error ? t.sh.wxIcon(t.w.code, t.w.day) : ""; color: "#ffffff"; font.pixelSize: 54; font.family: t.nerd; anchors.verticalCenter: parent.verticalCenter }
                        Column { anchors.verticalCenter: parent.verticalCenter
                            Text { text: t.w && !t.w.error ? t.w.temp + "°" : ""; color: "#ffffff"; font.pixelSize: 46; font.bold: true; font.family: t.nerd }
                            Text { text: t.w && !t.w.error ? t.sh.wxText(t.w.code) : ""; color: "#e8d9ff"; font.pixelSize: 14; font.family: t.nerd }
                        }
                    }
                    Text { text: t.w && !t.w.error ? "feels like " + t.w.feels + "°   ·   humidity " + t.w.hum + " %" : ""; color: "#d8c8ff"; font.pixelSize: 11; font.family: t.nerd }
                    Text { text: t.w && !t.w.error ? "Wind " + t.w.wind + " km/h   ·    " + t.w.sunrise + "    " + t.w.sunset : ""; color: "#d8c8ff"; font.pixelSize: 11; font.family: t.nerd }
                }
            }

            SecLabel { visible: t.w && t.w.error === undefined; text: "NEXT HOURS" }
            Flickable {
                visible: t.w && t.w.error === undefined
                width: parent.width; height: 106; contentWidth: hrow.implicitWidth; clip: true; boundsBehavior: Flickable.StopAtBounds
                Row { id: hrow; spacing: 6
                    Repeater {
                        model: t.w && t.w.hours ? t.w.hours : []
                        delegate: Rectangle { required property var modelData; width: 56; height: 100; radius: 14; color: "#12ffffff"
                            Column { anchors.centerIn: parent; spacing: 5
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; color: "#8a86a6"; font.pixelSize: 11; font.family: t.nerd }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: t.sh.wxIcon(modelData.code, 1); color: "#c0a0ff"; font.pixelSize: 20; font.family: t.nerd }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.temp + "°"; color: "#ffffff"; font.pixelSize: 14; font.bold: true; font.family: t.nerd }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.p + "%"; color: modelData.p >= 50 ? "#7ad6d0" : "#6a6685"; font.pixelSize: 10; font.family: t.nerd }
                            } }
                    }
                }
            }

            SecLabel { visible: t.w && t.w.error === undefined; text: "FORECAST" }
            Repeater {
                model: t.w && t.w.days ? t.w.days : []
                delegate: Rectangle { required property var modelData; required property int index
                    width: col.width; height: 46; radius: 14; color: "#10ffffff"
                    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: t.dayName(modelData.d, index); color: "#ffffff"; font.pixelSize: 13; font.family: t.nerd; width: 52 }
                    Text { x: 70; anchors.verticalCenter: parent.verticalCenter; text: t.sh.wxIcon(modelData.code, 1); color: "#c0a0ff"; font.pixelSize: 20; font.family: t.nerd; width: 30 }
                    Text { x: 106; anchors.verticalCenter: parent.verticalCenter; text: " " + modelData.p + "%"; color: modelData.p >= 50 ? "#7ad6d0" : "#6a6685"; font.pixelSize: 11; font.family: t.nerd; width: 60 }
                    Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: modelData.min + "°  /  " + modelData.max + "°"; color: "#e6e2f7"; font.pixelSize: 13; font.bold: true; font.family: t.nerd }
                }
            }
            Row { spacing: 8
                Chip { text: "Change city"; icon: ""; onClicked: { Quickshell.execDetached([t.sh.scripts + "weather-city.sh"]); t.sh.open = false } }
                Chip { text: "Refresh"; icon: ""; onClicked: { Quickshell.execDetached(["rm", "-f", Quickshell.env("HOME") + "/.cache/qs-weather.json"]); wp.refresh() } }
            }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: "Data: Open-Meteo. Default city is Vienna."; color: "#6a6685"; font.pixelSize: 10; font.family: t.nerd }
        }
    }
    ScrollHint { target: fl; active: t.active }
}
