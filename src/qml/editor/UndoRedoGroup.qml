/* SPDX-FileCopyrightText: 2022 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kquickimageeditor

Grid {
    id: root

    property int focusPolicy: Qt.StrongFocus
    property real buttonHeight: undoButton.implicitHeight
    property bool animationsEnabled: true

    spacing: Kirigami.Units.mediumSpacing
    columns: flow === Grid.LeftToRight ? visibleChildren.length : 1
    rows: flow === Grid.TopToBottom ? visibleChildren.length : 1

    required property AnnotationDocument document

    add: Transition {
        enabled: root.animationsEnabled
        NumberAnimation { properties: "x,y"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }

    Controls.ToolButton {
        id: undoButton

        enabled: root.document.undoStackDepth > 0
        height: root.buttonHeight
        focusPolicy: root.focusPolicy
        display: Controls.ToolButton.IconOnly
        text: i18nc("@action:button", "Undo")
        icon.name: "edit-undo"
        autoRepeat: true
        onClicked: root.document.undo()

        Controls.ToolTip.text: text
        Controls.ToolTip.visible: (hovered || pressed) && display === Controls.ToolButton.IconOnly
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    Controls.ToolButton {
        id: redoButton

        enabled: root.document.redoStackDepth > 0
        height: root.buttonHeight
        focusPolicy: root.focusPolicy
        display: Controls.ToolButton.IconOnly
        text: i18nc("@action:button", "Redo")
        icon.name: "edit-redo"
        autoRepeat: true
        onClicked: root.document.redo()

        Controls.ToolTip.text: text
        Controls.ToolTip.visible: (hovered || pressed) && display === Controls.ToolButton.IconOnly
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    Controls.ToolSeparator {
        height: root.flow === Grid.TopToBottom ? implicitWidth : parent.height
        width: root.flow === Grid.TopToBottom ? parent.width : implicitWidth
    }
}
