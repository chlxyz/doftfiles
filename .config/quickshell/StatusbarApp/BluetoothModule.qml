import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: bt
    property bool focused: false
    function activate(): void { Quickshell.execDetached(["qs","ipc","call","controlcenter","toggle"]) }
    readonly property bool active: ma.containsMouse || bt.focused
    implicitWidth: row.implicitWidth + 10
    implicitHeight: 30
    radius: 15
    color: active ? Theme.primary : "transparent"
    Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.OutQuint } }
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Text {
            text: ""
            color: bt.active ? Theme.background : Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bt.activate() }
}
