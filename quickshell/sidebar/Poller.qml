import QtQuick
import Quickshell.Io

// runs a command that prints one JSON document, keeps the parsed result in `data`
Item {
    id: p
    property var command: []
    property int interval: 3000
    property bool active: false
    property var res: null
    function refresh() { if (!proc.running) proc.running = true }
    Process {
        id: proc
        command: p.command
        stdout: StdioCollector { onStreamFinished: { try { p.res = JSON.parse(this.text) } catch (e) { } } }
    }
    Timer { interval: p.interval; repeat: true; running: p.active; triggeredOnStart: true; onTriggered: p.refresh() }
}
