/*
 *  SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as Controls

import org.kde.kirigami as Kirigami

Controls.Control {
    id: root
    anchors.bottom: parent.bottom
    anchors.bottomMargin: -background.border.width

    property string text: ""

    property alias parentHovered: hoverHandler.hovered
    property alias parentPoint: hoverHandler.point

    HoverHandler {
        id: hoverHandler
        parent: root.parent
        target: root.parent

        readonly property bool swapSides: {
            if (!hovered) {
                return false;
            }

            const p = point.position;
            const px = Math.round(root.parent instanceof Flickable ? p.x - root.parent.contentX : p.x);
            const py = Math.round(root.parent instanceof Flickable ? p.y - root.parent.contentY : p.y);

            if (root.mirrored) {
                return px >= (root.parent.width - root.effectiveWidth) && py >= (root.parent.height - root.effectiveHeight);
            } else {
                return px <= root.effectiveWidth && py >= (root.parent.height - root.effectiveHeight);
            }
        }
    }

    states: [
        State {
            name: "left"
            when: !hoverHandler.swapSides
            AnchorChanges {
                target: root
                anchors.left: root.parent.left
                anchors.right: undefined
            }
            PropertyChanges {
                target: root
                anchors.leftMargin: -root.background.border.width
                anchors.rightMargin: 0
                background.topLeftRadius: root.mirrored ? Kirigami.Units.cornerRadius : 0
                background.topRightRadius: root.mirrored ? 0 : Kirigami.Units.cornerRadius
            }
        },
        State {
            name: "right"
            when: hoverHandler.swapSides
            AnchorChanges {
                target: root
                anchors.left: undefined
                anchors.right: root.parent.right
            }
            PropertyChanges {
                target: root
                anchors.leftMargin: 0
                anchors.rightMargin: -root.background.border.width
                background.topLeftRadius: root.mirrored ? 0 : Kirigami.Units.cornerRadius
                background.topRightRadius: root.mirrored ? Kirigami.Units.cornerRadius : 0
            }
        }
    ]

    hoverEnabled: false

    width: Math.min(implicitWidth, parent.width - Kirigami.Units.gridUnit)

    readonly property real effectiveWidth: width - background.border.width
    readonly property real effectiveHeight: height - background.border.width

    padding: Kirigami.Units.smallSpacing + background.border.width

    Accessible.role: Accessible.StatusBar

    opacity: text.length === 0 ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }
    visible: opacity > 0

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Kirigami.ColorUtils.linearInterpolation(
            Kirigami.Theme.backgroundColor,
            Kirigami.Theme.textColor,
            Kirigami.Theme.frameContrast
        )
    }

    contentItem: Controls.Label {
        // Don't update text when it's empty, just let us fade away
        text: root.text.length === 0 ? text : root.text
        maximumLineCount: 1
        elide: Text.ElideMiddle
    }
}
