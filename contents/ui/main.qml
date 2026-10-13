import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts
import org.kde.ksysguard.sensors as Sensors
import org.kde.ksysguard.formatter as Fmt

PlasmoidItem {
    id: root

    readonly property int rate: 2000
    readonly property int maxSamples: 300      // 300 × 2 s = 10 min
    readonly property real tempWarn: 75
    readonly property real tempCrit: 85

    // Verlauf nur im RAM; immer kopieren und neu zuweisen, damit Bindings feuern
    property var hist: ({ cpu: [], temp: [], gpu: [], vram: [], ram: [], down: [], up: [] })

    // all-Sensoren, damit das Widget auf anderen Rechnern ohne Änderung läuft;
    // ponytail: Lüfter/Leistung fest auf gpu0, bei mehreren GPUs eigene Auswahl
    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: root.rate }
    Sensors.Sensor { id: cpuTemp; sensorId: "cpu/all/averageTemperature"; updateRateLimit: root.rate }
    Sensors.Sensor { id: cores; sensorId: "cpu/all/coreCount" }
    Sensors.Sensor { id: threads; sensorId: "cpu/all/cpuCount" }
    Sensors.Sensor { id: gpu; sensorId: "gpu/all/usage"; updateRateLimit: root.rate }
    Sensors.Sensor { id: vram; sensorId: "gpu/all/usedVram"; updateRateLimit: root.rate }
    Sensors.Sensor { id: vramTotal; sensorId: "gpu/all/totalVram" }
    Sensors.Sensor { id: gpuFan; sensorId: "gpu/gpu0/fan1"; updateRateLimit: root.rate }
    Sensors.Sensor { id: gpuPower; sensorId: "gpu/gpu0/power1"; updateRateLimit: root.rate }
    Sensors.Sensor { id: ram; sensorId: "memory/physical/used"; updateRateLimit: root.rate }
    Sensors.Sensor { id: ramPct; sensorId: "memory/physical/usedPercent"; updateRateLimit: root.rate }
    Sensors.Sensor { id: ramTotal; sensorId: "memory/physical/total" }
    Sensors.Sensor { id: down; sensorId: "network/all/download"; updateRateLimit: root.rate }
    Sensors.Sensor { id: up; sensorId: "network/all/upload"; updateRateLimit: root.rate }

    readonly property real vramPct: vramTotal.value > 0 ? vram.value / vramTotal.value * 100 : 0

    function num(v) { return isFinite(v) ? v : 0 }
    function push(a, v) { return a.concat([num(v)]).slice(-maxSamples) }
    function sample() {
        hist = {
            cpu: push(hist.cpu, cpu.value), temp: push(hist.temp, cpuTemp.value),
            gpu: push(hist.gpu, gpu.value), vram: push(hist.vram, vramPct),
            ram: push(hist.ram, ramPct.value),
            down: push(hist.down, down.value), up: push(hist.up, up.value)
        }
    }
    Timer { interval: root.rate; running: true; repeat: true; onTriggered: root.sample() }

    function fmt(s) { return s.formattedValue || "–" }
    function fmtAs(v, s) { return Fmt.Formatter.formatValue(v, s.unit) }
    function tempColor(t) {
        if (t >= tempCrit) return Kirigami.Theme.negativeTextColor
        if (t >= tempWarn) return Kirigami.Theme.neutralTextColor
        return Kirigami.Theme.textColor
    }

    // Eine Gruppe je Spalte (Leiste) bzw. Karte (große Ansicht).
    // vals: zwei Werte; die ersten series.length Werte bekommen einen Farbpunkt ihrer Reihe.
    readonly property real netMax: Math.max(...hist.down, ...hist.up, 1)
    readonly property var groups: [
        { name: "CPU", title: "Prozessor", icon: "cpu", pre: ["", ""], units: [cpu.unit, cpuTemp.unit],
          vals: [{ label: "Auslastung", text: fmt(cpu) },
                 { label: "Temperatur", text: fmt(cpuTemp), color: tempColor(cpuTemp.value) }],
          series: [{ data: hist.cpu, color: Kirigami.Theme.highlightColor },
                   { data: hist.temp, color: Kirigami.Theme.neutralTextColor }],
          max: 100,
          extra: cores.value + " Kerne · " + threads.value + " Threads" },
        { name: "GPU", title: "Grafikkarte", icon: "video-display", pre: ["", ""], units: [gpu.unit, vram.unit],
          vals: [{ label: "Auslastung", text: fmt(gpu) },
                 { label: "VRAM", text: fmt(vram) }],
          series: [{ data: hist.gpu, color: Kirigami.Theme.highlightColor },
                   { data: hist.vram, color: Kirigami.Theme.visitedLinkColor }],
          max: 100,
          extra: "Lüfter " + fmt(gpuFan) + " · Leistung " + fmt(gpuPower) + " · VRAM gesamt " + fmt(vramTotal) },
        { name: "RAM", title: "Arbeitsspeicher", icon: "media-flash", pre: ["", ""], units: [ram.unit, ramPct.unit],
          vals: [{ label: "Belegt", text: fmt(ram) },
                 { label: "", text: fmt(ramPct) }],
          series: [{ data: hist.ram, color: Kirigami.Theme.highlightColor }],
          max: 100,
          extra: "Gesamt " + fmt(ramTotal) },
        { name: "NET", title: "Netzwerk", icon: "network-wired", pre: ["↓ ", "↑ "], units: [down.unit, up.unit],
          vals: [{ label: "Download", text: fmt(down) },
                 { label: "Upload", text: fmt(up) }],
          series: [{ data: hist.down, color: Kirigami.Theme.positiveTextColor },
                   { data: hist.up, color: Kirigami.Theme.highlightColor }],
          max: netMax,
          extra: "max " + fmtAs(netMax, down) + " in 10 min" }
    ]

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    toolTipMainText: "Systemauslastung"
    toolTipSubText: groups.map(g => g.title + ": " + g.vals.map((v, i) => g.pre[i] + v.text).join(" · ")).join("\n")

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth
        Layout.preferredWidth: row.implicitWidth
        onClicked: root.expanded = !root.expanded

        FontMetrics { id: fm }

        // Je Gruppe: Kennung | zwei Werte untereinander, feste Breite gegen Springen
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing
            Repeater {
                model: root.groups.length
                RowLayout {
                    readonly property var g: root.groups[index]
                    spacing: Kirigami.Units.smallSpacing
                    PC.Label { text: g.name; opacity: 0.6 }
                    ColumnLayout {
                        spacing: 0
                        Repeater {
                            model: 2
                            PC.Label {
                                readonly property var v: g.vals[index]
                                text: g.pre[index] + v.text
                                color: v.color || Kirigami.Theme.textColor
                                font.features: { "tnum": 1 }
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: Math.max(...[0, 1].map(i =>
                                    fm.advanceWidth(g.pre[i]) + Fmt.Formatter.maximumLength(g.units[i], font)))
                            }
                        }
                    }
                }
            }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: implicitHeight
        spacing: Kirigami.Units.mediumSpacing

        RowLayout {
            Kirigami.Icon { source: "utilities-system-monitor"; implicitWidth: Kirigami.Units.iconSizes.large; implicitHeight: implicitWidth }
            Kirigami.Heading { text: "Systemauslastung"; level: 3; Layout.fillWidth: true }
        }

        Repeater {
            model: root.groups.length
            Rectangle {
                readonly property var g: root.groups[index]
                Layout.fillWidth: true
                implicitHeight: card.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: Kirigami.Theme.alternateBackgroundColor

                ColumnLayout {
                    id: card
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon { source: g.icon; implicitWidth: Kirigami.Units.iconSizes.smallMedium; implicitHeight: implicitWidth }
                        Kirigami.Heading { text: g.title; level: 4; Layout.fillWidth: true }
                        Repeater {
                            model: g.vals.length
                            RowLayout {
                                readonly property var v: g.vals[index]
                                spacing: Kirigami.Units.smallSpacing
                                Rectangle {
                                    visible: index < g.series.length
                                    implicitWidth: Kirigami.Units.smallSpacing * 2
                                    implicitHeight: implicitWidth
                                    radius: width / 2
                                    color: index < g.series.length ? g.series[index].color : "transparent"
                                }
                                PC.Label { visible: v.label !== ""; text: v.label; opacity: 0.7 }
                                PC.Label {
                                    text: v.text
                                    color: v.color || Kirigami.Theme.textColor
                                    font.bold: true
                                    font.features: { "tnum": 1 }
                                }
                            }
                        }
                    }

                    // Feste Zeitachse: maxSamples Werte = volle Breite, neuester Wert rechts
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                        Charts.LineChart {
                            id: chart
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0, g.series[0].data.length - 1) / (root.maxSamples - 1)
                            yRange { from: 0; to: g.max; automatic: false }
                            lineWidth: 1.5
                            fillOpacity: 0.15
                            colorSource: Charts.ArraySource { array: g.series.map(x => x.color) }
                            Instantiator {
                                model: g.series.length
                                delegate: Charts.ArraySource { array: g.series[index].data }
                                onObjectAdded: (k, o) => chart.insertValueSource(k, o)
                                onObjectRemoved: (k, o) => chart.removeValueSource(o)
                            }
                        }
                    }

                    PC.Label {
                        text: g.extra
                        font: Kirigami.Theme.smallFont
                        opacity: 0.7
                    }
                }
            }
        }
    }
}
