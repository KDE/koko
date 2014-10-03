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

    // This rectangle is relative to the source
    property rect rectangle
    property string color: "black"
    property double opac: 0.4

    Rectangle {
        id: topRect
        color: root.color
        opacity: root.opac

        x: source.x
        y: source.y
        width: source.width
        height: rectangle.y - source.y
    }
    Rectangle {
        id: bottomRect
        color: root.color
        opacity: root.opac

        x: source.x
        y: source.y + rectangle.y + rectangle.height
        width: source.width
        height: source.height - (source.y + rectangle.y)
    }
    Rectangle {
        id: leftRect
        color: root.color
        opacity: root.opac

        x: source.x
        y: source.y + rectangle.y
        width: rectangle.x
        height: rectangle.height
    }
    Rectangle {
        id: rightRect
        color: root.color
        opacity: root.opac

        x: source.x + rectangle.x + rectangle.width
        y: source.y + rectangle.y
        width: source.width - rectangle.y
        height: rectangle.height
    }

    //
    // Border
    //
    Rectangle {
        id: rectBorder
        color: "transparent"

        x: source.x + rectangle.x
        y: source.y + rectangle.y
        width: rectangle.width
        height: rectangle.height

        border.color: "white"
        border.width: 1
    }
}
