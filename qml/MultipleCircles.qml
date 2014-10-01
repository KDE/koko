/*
 *   Copyright 2014 by Vishesh Handa <vhanda@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.0

Item {
    id: root

    // Each circle is positioned around a bigger invisible circle
    // This radius is the radius of that outer circle
    property int radius: width / 4
    property int originX: width / 2
    property int originY: height / 2

    property alias colors: rep.model

    Repeater {
        id: rep
        anchors.fill: parent

        property int degree: 360 / count

        Circle {
            // The extra -radius is because it needs to be rendered on the top left
            x: originX + (Math.cos(index * (rep.degree * Math.PI / 180))*root.radius) - radius
            y: originY - (Math.sin(index * (rep.degree * Math.PI / 180))*root.radius) - radius
            radius: root.radius * 0.8
            color: model.modelData
        }
    }
}
