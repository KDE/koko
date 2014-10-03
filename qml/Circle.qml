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
    property int radius
    property alias color : tagCircle.color

    //
    // Sometimes the circle is assumed to be at (x,y) but it isn't
    // because it is drawn from (x,y). These variables can then
    // be used to adjust where the circle is drawn.
    // In the above example, it should be (-radius, -radius)
    //
    property int xPadding: 0
    property int yPadding: 0

    width: radius * 2
    height: radius * 2

    Rectangle {
        id: tagCircle
        radius: parent.radius

        width: parent.width
        height: parent.height
        x: xPadding
        y: yPadding
    }
}
