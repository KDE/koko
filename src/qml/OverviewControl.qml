/* SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15

Rectangle {
    id: root
    property Flickable target: null
    property alias pressed: mouseArea.pressed
    property real contentAspectRatio: target ? target.contentWidth / target.contentHeight : 1
    property real widthRatio: target ? target.visibleArea.widthRatio : 1
    property real heightRatio: target ? target.visibleArea.heightRatio : 1
    // Don't use Flickable::visibleArea.xPosition or Flickable::visibleArea.yPosition. They won't give the correct values.
    property real normalizedX: target ? target.contentX / (target.contentWidth - target.width) : 0
    property real normalizedY: target ? target.contentY / (target.contentHeight - target.height) : 0
    readonly property real preferredWidth: contentAspectRatio >= 1 || contentAspectRatio <= 0 ?
        implicitWidth : height * (1 / contentAspectRatio)
    readonly property real preferredHeight: contentAspectRatio <= 1 ?
        implicitHeight : width / contentAspectRatio
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
        antialiasing: false
        x: root.normalizedX * (root.width - handleRect.width)
        y: root.normalizedY * (root.height - handleRect.height)
        width: root.width * root.widthRatio
        height: root.height * root.heightRatio
        color: Qt.rgba(1,1,1,0.25)
        border.color: Qt.rgba(1,1,1,0.5)
        border.width: 1
        Rectangle {
            id: dot // For improved visibility
            visible: {
                const w = implicitWidth - border.width * 2
                const h = implicitHeight - border.width * 2
                return parent.width - w >= w && parent.height - h >= h
            }
            radius: height / 2
            anchors.centerIn: parent
            implicitWidth: 6
            implicitHeight: 6
            color: "white"
            // shadow outline for slightly better contrast
            border.color: Qt.rgba(0,0,0,0.125)
            border.width: 1
        }
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true
    }
    Binding {
        target: root
        property: "normalizedX"
        value: {
            const newX = Math.max(0, // min value
                Math.min(mouseArea.mouseX - handleRect.width / 2, // value
                    root.width - handleRect.width)) // max value
            return newX / (root.width - handleRect.width)
        }
        when: mouseArea.pressed
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: root
        property: "normalizedY"
        value: {
            const newY = Math.max(0, // min value
                Math.min(mouseArea.mouseY - handleRect.height / 2, // value
                    root.height - handleRect.height)) // max value
            return newY / (root.height - handleRect.height)
        }
        when: mouseArea.pressed
        restoreMode: Binding.RestoreBinding
    }
}
