import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import qs.CustomTheme

// ponytail: single combined dropdown for volume/brightness/wifi/bt — minimal, no extra deps
PanelWindow {
    id: root
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore
    color: "transparent"
    anchors { top: true; right: true }
    // offset from top bar (bar is at top, reserve 72). Dropdown appears below it.
    margins { right: 12 }
    margins.top: 72 + currentTop
    implicitWidth: 360
    implicitHeight: contentBg.implicitHeight + 24

    property bool isOpen: false
    property bool showWindow: false
    onIsOpenChanged: { if (isOpen) showWindow = true }
    visible: showWindow || slideAnim.running

    // slide from top
    property real slideOff: -600
    property real slideOn: 0
    property real currentTop: isOpen ? slideOn : slideOff
    Behavior on currentTop {
        NumberAnimation { id: slideAnim; duration: 350; easing.type: Easing.OutQuint; onRunningChanged: { if (!running && !root.isOpen) root.showWindow = false } }
    }

    HyprlandFocusGrab { windows: [root]; active: root.isOpen; onCleared: root.isOpen = false }
    Shortcut { sequence: "Escape"; onActivated: root.isOpen = false }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
    }

    // --- audio ---
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink !== null && sink.ready && sink.audio !== null
    PwObjectTracker { objects: sink !== null ? [sink] : [] }
    function setVol(v: real) { if (!sinkReady) return; sink.audio.muted=false; sink.audio.volume=Math.max(0,Math.min(1,v)) }

    // --- helpers ---
    component CCSlider: Slider {
        id: s
        Layout.fillWidth: true
        from: 0; to: 100
        background: Rectangle {
            x: s.leftPadding; y: s.topPadding + s.availableHeight/2 - height/2
            width: s.availableWidth; height: 6; radius: 3
            color: Theme.background; border.color: Theme.primary; border.width: 1
            Rectangle { width: s.visualPosition*parent.width; height: parent.height; radius: 3; color: Theme.primary }
        }
        handle: Rectangle {
            x: s.leftPadding + s.visualPosition*(s.availableWidth-width)
            y: s.topPadding + s.availableHeight/2 - height/2
            implicitWidth: 16; implicitHeight: 16; radius: 8
            color: s.pressed ? Theme.background : Theme.primary; border.color: Theme.primary; border.width: 1
        }
    }

    component TRow: RowLayout {
        id: r
        property string title: ""
        property string iconSrc: ""
        property bool toggleOn: false
        signal toggled(bool on)
        Layout.fillWidth: true; spacing: 12
        Image { source: r.iconSrc; Layout.preferredWidth: 20; Layout.preferredHeight: 20; sourceSize.width: 20; sourceSize.height: 20; fillMode: Image.PreserveAspectFit; layer.enabled: true; layer.effect: MultiEffect { colorization: 1.0; colorizationColor: Theme.primary } }
        Text { text: r.title; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true; Layout.fillWidth: true }
        Switch {
            id: sw
            checked: r.toggleOn
            onClicked: r.toggled(checked)
            indicator: Rectangle {
                implicitWidth: 42; implicitHeight: 24; radius: 12
                color: sw.checked ? Theme.primary : Theme.background
                border.color: Theme.primary; border.width: 1
                Rectangle {
                    x: sw.checked ? parent.width-width-2 : 2; y: 2
                    implicitWidth: 20; implicitHeight: 20; radius: 10
                    color: sw.checked ? Theme.background : Theme.primary
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
            }
        }
    }

    // --- panel bg ---
    Item {
        anchors.fill: parent
        RectangularShadow {
            anchors.fill: bg
            radius: bg.radius; blur: 15
            color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.4)
        }
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 14
            gradient: Gradient { orientation: Gradient.Vertical; GradientStop { position: 0.0; color: Theme.primary } GradientStop { position: 1.0; color: Theme.on_primary } }
            Rectangle {
                id: contentBg
                anchors.fill: parent; anchors.margins: 2
                radius: parent.radius - 2
                color: Theme.background
                implicitHeight: col.implicitHeight + 32

                ColumnLayout {
                    id: col
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 14

                    Text { text: "Control Center"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.25 }

                    // Volume
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Image { source: "../shared/icons/volume.svg"; Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize.width: 18; sourceSize.height: 18; fillMode: Image.PreserveAspectFit; layer.enabled: true; layer.effect: MultiEffect { colorization:1.0; colorizationColor: Theme.primary } }
                        Text { text: "Volume"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.preferredWidth: 70 }
                        CCSlider {
                            id: volSlider
                            value: sinkReady ? Math.round(sink.audio.volume*100) : 0
                            onMoved: root.setVol(value/100)
                            // sync from pipewire when changed externally
                            Connections {
                                target: sinkReady ? sink.audio : null
                                ignoreUnknownSignals: true
                                function onVolumeChanged() { volSlider.value = Math.round(sink.audio.volume*100) }
                            }
                        }
                        Text { text: (sinkReady ? (sink.audio.muted ? "Muted" : Math.round(sink.audio.volume*100)+"%") : "--"); color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight }
                        MouseArea {
                            width: 18; height: 18; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (sinkReady) sink.audio.muted = !sink.audio.muted }
                            Image { anchors.fill: parent; source: "../shared/icons/volume-muted.svg"; sourceSize.width: 18; sourceSize.height: 18; fillMode: Image.PreserveAspectFit; layer.enabled: true; layer.effect: MultiEffect { colorization:1.0; colorizationColor: Theme.primary } }
                        }
                    }

                    // Brightness
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Image { source: "../shared/icons/brightness.svg"; Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize.width: 18; sourceSize.height: 18; fillMode: Image.PreserveAspectFit; layer.enabled: true; layer.effect: MultiEffect { colorization:1.0; colorizationColor: Theme.primary } }
                        Text { text: "Brightness"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.preferredWidth: 70 }
                        CCSlider {
                            id: brightSlider
                            from: 10; to: 100; value: 100
                            onMoved: Quickshell.execDetached(["bash","-c","brightnessctl set "+Math.round(value)+"%"])
                            Process {
                                command: ["bash","-c","brightnessctl -m | awk -F, '{gsub(\"%\",\"\",$4); print $4}'"]
                                running: root.isOpen
                                stdout: StdioCollector { onStreamFinished: { let v=parseInt(this.text.trim()); if(!isNaN(v)) brightSlider.value=Math.max(10,v) } }
                            }
                        }
                        Text { text: Math.round(brightSlider.value)+"%"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.25 }

                    // Wifi
                    TRow {
                        id: wifiRow
                        title: wifiEnabled ? (wifiSsid !== "" ? wifiSsid : "Wi-Fi") : "Wi-Fi Off"
                        iconSrc: "../shared/icons/launcher.svg"
                        toggleOn: wifiEnabled
                        onToggled: (on) => {
                            Quickshell.execDetached(["bash","-c", on ? "nmcli radio wifi on" : "nmcli radio wifi off"])
                            // re-query after 800ms
                            wifiProc.running = true
                        }
                        property bool wifiEnabled: false
                        property string wifiSsid: ""
                        Process {
                            id: wifiProc
                            command: ["bash","-c","nmcli -t -f WIFI g 2>/dev/null | tr -d '[:space:]'; echo \"---\"; nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -n1"]
                            running: root.isOpen
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    let parts=this.text.trim().split("---")
                                    let en=(parts[0]||"").trim()
                                    wifiRow.wifiEnabled = (en === "enabled")
                                    wifiRow.wifiSsid = (parts[1]||"").trim()
                                }
                            }
                        }
                    }

                    // quick wifi actions
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Button {
                            Layout.fillWidth: true
                            text: "Networks"
                            onClicked: { root.isOpen=false; Quickshell.execDetached(["bash","-c", Quickshell.env("HOME")+"/.config/ml4w/settings/networkmanager.sh"]) }
                            background: Rectangle { color: "transparent"; border.color: Theme.primary; border.width: 1; radius: 8 }
                            contentItem: Text { text: parent.text; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; padding: 6 }
                        }
                        Button {
                            text: "Settings"
                            onClicked: { root.isOpen=false; Quickshell.execDetached(["nm-connection-editor"]) }
                            background: Rectangle { color: "transparent"; border.color: Theme.primary; border.width: 1; radius: 8 }
                            contentItem: Text { text: parent.text; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; padding: 6 }
                        }
                    }

                    // Bluetooth
                    TRow {
                        id: btRow
                        title: btEnabled ? "Bluetooth" : "Bluetooth Off"
                        iconSrc: "../shared/icons/power.svg"
                        toggleOn: btEnabled
                        onToggled: (on) => {
                            Quickshell.execDetached(["bash","-c", on ? "bluetoothctl power on" : "bluetoothctl power off"])
                            btProc.running = true
                        }
                        property bool btEnabled: false
                        Process {
                            id: btProc
                            command: ["bash","-c","bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 1 || echo 0"]
                            running: root.isOpen
                            stdout: StdioCollector { onStreamFinished: { btRow.btEnabled = (this.text.trim()==="1") } }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Button {
                            Layout.fillWidth: true
                            text: "Devices"
                            onClicked: { root.isOpen=false; Quickshell.execDetached(["blueman-manager"]) }
                            background: Rectangle { color: "transparent"; border.color: Theme.primary; border.width: 1; radius: 8 }
                            contentItem: Text { text: parent.text; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; padding: 6 }
                        }
                        Button {
                            text: "Scan"
                            onClicked: Quickshell.execDetached(["bash","-c","bluetoothctl scan on & sleep 4; bluetoothctl scan off; echo done"])
                            background: Rectangle { color: "transparent"; border.color: Theme.primary; border.width: 1; radius: 8 }
                            contentItem: Text { text: parent.text; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; padding: 6 }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.25 }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Button {
                            Layout.fillWidth: true; text: "Sound"
                            onClicked: { root.isOpen=false; Quickshell.execDetached(["pavucontrol"]) }
                            background: Rectangle { color: "transparent"; border.color: Theme.primary; border.width: 1; radius: 8 }
                            contentItem: Text { text: parent.text; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; padding: 6 }
                        }
                        Button {
                            Layout.fillWidth: true; text: "Sidebar"
                            onClicked: { root.isOpen=false; Quickshell.execDetached(["qs","ipc","call","sidebar","toggle"]) }
                            background: Rectangle { color: "transparent"; border.color: Theme.primary; border.width: 1; radius: 8 }
                            contentItem: Text { text: parent.text; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; padding: 6 }
                        }
                    }
                }
            }
        }
    }
}
