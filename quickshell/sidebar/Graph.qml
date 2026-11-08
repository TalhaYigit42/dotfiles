import QtQuick

Canvas {
    id: g
    property var values: []
    property real maxV: 100
    property color line: "#a77bff"
    property bool grid: true
    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        var w = width, h = height
        if (grid) {
            ctx.strokeStyle = "rgba(255,255,255,0.08)"; ctx.lineWidth = 1
            for (var i = 1; i < 4; i++) { ctx.beginPath(); ctx.moveTo(0, h * i / 4); ctx.lineTo(w, h * i / 4); ctx.stroke() }
        }
        var v = values
        if (!v || v.length < 2) return
        var n = v.length, m = Math.max(0.0001, maxV)
        var step = w / (60 - 1)
        var x0 = w - (n - 1) * step
        ctx.beginPath()
        for (var k = 0; k < n; k++) {
            var x = x0 + k * step, y = h - Math.min(1, v[k] / m) * (h - 3) - 1.5
            if (k === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
        }
        ctx.strokeStyle = line; ctx.lineWidth = 2; ctx.lineJoin = "round"; ctx.stroke()
        ctx.lineTo(w, h); ctx.lineTo(x0, h); ctx.closePath()
        var gr = ctx.createLinearGradient(0, 0, 0, h)
        gr.addColorStop(0, Qt.rgba(line.r, line.g, line.b, 0.35)); gr.addColorStop(1, Qt.rgba(line.r, line.g, line.b, 0.02))
        ctx.fillStyle = gr; ctx.fill()
    }
}
