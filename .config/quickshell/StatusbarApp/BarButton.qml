import QtQuick
import QtQuick.Effects
import qs.CustomTheme

// Reusable round icon button used across the status bar modules.
Rectangle {
    id: btn
    property string iconSrc: ""
    property bool colorize: true
    // Set by the keyboard navigation in StatusbarWindow to highlight the
    // currently selected module.
    property bool focused: false
    signal clicked()

    // Run the button's action (mouse click or keyboard Return).
    function activate(): void { btn.clicked() }

    // Highlighted when hovered with the mouse or selected via the keyboard.
    readonly property bool active: mouseArea.containsMouse || btn.focused
    readonly property bool isDark: (0.299 * Theme.background.r + 0.587 * Theme.background.g + 0.114 * Theme.background.b) < 0.5

    implicitWidth: 30
    implicitHeight: 30
    radius: 15

    // Every button gets the same accent-filled circle on hover/selection.
    // ponytail: black bar — white active, black icon; light glass — black active, white icon
    color: btn.active ? (btn.isDark ? "#ffffff" : "#000000") : "transparent"

    // Fade the accent circle in on hover/selection and out again on leave.
    Behavior on color {
        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
    }

    Image {
        anchors.centerIn: parent
        source: btn.iconSrc
        width: 18
        height: 18
        sourceSize.width: 18
        sourceSize.height: 18
        fillMode: Image.PreserveAspectFit
        layer.enabled: btn.colorize
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: btn.active ? (btn.isDark ? "#000000" : "#ffffff") : (btn.isDark ? "#ffffff" : "#000000")

            // Recolor the icon in step with the circle fade.
            Behavior on colorizationColor {
                ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
