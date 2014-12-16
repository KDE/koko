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
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0

import QtGraphicalEffects 1.0

Item {
    property alias imageSource: img.source
    property bool hover: false
    property bool isCurrentItem: false

    Image {
        id: img
        asynchronous: true
        width: 300
        height: 300
        sourceSize: Qt.size(300, 300)

        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        visible: false
    }

    Rectangle {
        id: maskRect
        anchors.fill: parent
        radius: borderRect.radius

        antialiasing: true
        visible: false
    }

    OpacityMask {
        cached: true
        anchors.fill: parent
        source: img
        maskSource: maskRect
    }

    // We were using a GammaEffect before this, but that
    // resulted in really high cpu usage. Apparently mixing two
    // graphical effects is not ideal.
    Rectangle {
        id: gammaEffect
        anchors.fill: parent
        color: "white"
        radius: borderRect.radius
        opacity: hover ? 0.1 : 0.0
    }

    DropShadow {
        anchors.fill: parent
        radius: 18
        samples: 16
        fast: true
        color: "#80000000"
        source: maskRect
        cached: true
        z: -1
    }

    SystemPalette { id: sysPal; }
    Rectangle {
        id: borderRect
        anchors.fill: parent
        color: "#00000000"
        radius: img.width / 7

        antialiasing: true
        border.color: isCurrentItem ? sysPal.highlight : "#CCCCCC"
        border.width: isCurrentItem ? 5 : 1
    }
}
