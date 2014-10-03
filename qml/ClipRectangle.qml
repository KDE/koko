/*
 * Copyright (C) 2014 Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.1

Item {
    id: root
    property var source
    property rect rectangle: Qt.rect(topLeftHandle.x - source.x,
                                     topLeftHandle.y - source.y,
                                     bottomRightHandle.x - topLeftHandle.x + 1,
                                     bottomRightHandle.y - topLeftHandle.y + 1)
    property string color: "black"
    property double opac: 0.4

    property alias l: topLeftHandle.x
    property alias t: topLeftHandle.y
    property alias b: bottomRightHandle.y
    property alias r: bottomRightHandle.x

    DarkerOuterRectangle {
        source: root.source
        rectangle: root.rectangle
    }

    //
    // Handles
    //
    Circle {
        id: topLeftHandle
        radius: 10
        color: "white"

        x: source.x
        y: source.y
        xPadding: -radius
        yPadding: -radius

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            drag {
                target: parent
                axis: Drag.XandYAxis
                minimumX: source.x
                maximumX: root.r
                minimumY: source.y
                maximumY: root.b
            }
        }
    }

    Circle {
        id: bottomRightHandle
        radius: 10
        color: "white"

        x: source.x + source.width
        y: source.y + source.height
        xPadding: -radius
        yPadding: -radius

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            drag {
                target: parent
                axis: Drag.XandYAxis
                minimumX: root.l
                maximumX: source.x + source.width
                minimumY: root.t
                maximumY: source.y + source.height
            }
        }
    }

    Circle {
        id: topRightHandle
        x: bottomRightHandle.x
        y: topLeftHandle.y
        radius: 10
        color: "white"

        xPadding: -radius
        yPadding: -radius

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor
            drag {
                target: parent
                axis: Drag.XandYAxis
                minimumX: root.l
                maximumX: source.x + source.width
                minimumY: source.y
                maximumY: root.b
            }
        }

        onXChanged: bottomRightHandle.x = x
        onYChanged: topLeftHandle.y = y
    }

    Circle {
        id: bottomLeftHandle
        x: topLeftHandle.x
        y: bottomRightHandle.y
        radius: 10
        color: "white"

        xPadding: -radius
        yPadding: -radius

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor
            drag {
                target: parent
                axis: Drag.XandYAxis
                minimumX: source.x
                maximumX: root.r
                minimumY: root.t
                maximumY: source.y + source.height
            }
        }

        onXChanged: topLeftHandle.x = x
        onYChanged: bottomRightHandle.y = y
    }
}
