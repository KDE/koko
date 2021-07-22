/* SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15

Rectangle {
    id: root
    property Item target: null
    property alias pressed: mouseArea.pressed
    property real contentAspectRatio: target ? target.contentWidth / target.contentHeight : 1
    property real widthRatio: target ? target.width / target.contentWidth : 1
    property real heightRatio: target ? target.height / target.contentHeight : 1
    // Don't use Flickable::visibleArea.xPosition or Flickable::visibleArea.yPosition. They won't give the correct values.
    property real normalizedX: target ? -target.contentX / (target.contentWidth - target.width) : 0
    property real normalizedY: target ? -target.contentY / (target.contentHeight - target.height) : 0
    readonly property real preferredWidth: contentAspectRatio >= 1 || contentAspectRatio <= 0 ?
        implicitWidth : implicitHeight * (1 / contentAspectRatio)
    readonly property real preferredHeight: contentAspectRatio <= 1 ?
        implicitHeight : implicitWidth / contentAspectRatio
    implicitWidth: 100
    implicitHeight: 100
    width: preferredWidth
    height: preferredHeight
    color: Qt.rgba(0,0,0,0.5)
    border.color: Qt.rgba(1,1,1,1)
    border.width: 1
    antialiasing: false // no need for rounding now
    Rectangle {
        id: handleRect
        property bool mouseInside: mouseArea.mouseX >= handleRect.x
            && mouseArea.mouseX <= handleRect.x + handleRect.width
            && mouseArea.mouseY >= handleRect.y
            && mouseArea.mouseY <= handleRect.y + handleRect.height
        antialiasing: false
        width: Math.min(root.width * root.widthRatio, root.width)
        height: Math.min(root.height * root.heightRatio, root.height)
//         x: root.normalizedX * (root.width - handleRect.width)
        //y: root.normalizedY * (root.height - handleRect.height)
        color: Qt.rgba(1,1,1,0.25)
        border.color: Qt.rgba(1,1,1,0.5)
        border.width: 1
        Binding {
            target: handleRect
            property: "x"
            value: root.normalizedX * (root.width - handleRect.width)
            when: !mouseArea.pressed
            restoreMode: Binding.RestoreBinding
        }
        Binding {
            target: handleRect
            property: "y"
            value: root.normalizedY * (root.height - handleRect.height)
            when: !mouseArea.pressed
            restoreMode: Binding.RestoreBinding
        }
        //{
            //const newY = Math.max(0, // min
                //Math.min(handleRect.y,
                    //root.height - handleRect.height)) // max
            //return 
        //}
    }
    Rectangle {
        id: dot // For improved visibility
        radius: height / 2
        anchors.centerIn: handleRect
        implicitWidth: 6
        implicitHeight: 6
        color: "white"
        // shadow outline for slightly better contrast
        border.color: Qt.rgba(0, 0, 0,
            handleRect.width < dot.implicitWidth - 2
            || handleRect.height < dot.implicitHeight - 2 ?
                0.4 : 0.2)
        border.width: 1
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: if (pressed) {
            return Qt.ClosedHandCursor
        } else if (handleRect.mouseInside) {
            return Qt.OpenHandCursor
        } else {
            return Qt.ArrowCursor
        }
        preventStealing: true
        drag {
            axis: Drag.XAndYAxis
            target: handleRect
            minimumX: 0
            maximumX: root.width - handleRect.width
            minimumY: 0
            maximumY: root.height - handleRect.height
            threshold: 0
        }
        onPressed: if (!handleRect.mouseInside && !mouseArea.drag.active) {
            handleRect.x = Math.max(drag.minimumX, // min
                           Math.min(mouseArea.mouseX - handleRect.width / 2,
                                    drag.maximumX)) // max
            handleRect.y = Math.max(drag.minimumY, // min
                           Math.min(mouseArea.mouseY - handleRect.height / 2,
                                    drag.maximumY)) // max
        }
    }
    Binding {
        target: root
        property: "normalizedX"
        value: handleRect.x / (root.width - handleRect.width)
        when: mouseArea.pressed
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: root
        property: "normalizedY"
        value: handleRect.y / (root.height - handleRect.height)
        when: mouseArea.pressed
        restoreMode: Binding.RestoreBinding
    }
}
