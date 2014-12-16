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

AutomaticSpacingGrid {
    id: gridView

    signal albumSelected(var files)

    delegate: Item {
        width: cellWidth
        height: cellHeight

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            Album {
                id: album
                imageSource: model.cover
                isCurrentItem: gridView.currentIndex == model.index

                Layout.maximumWidth: 300
                Layout.maximumHeight: 300
                Layout.minimumWidth: 300
                Layout.minimumHeight: 300
            }

            SystemPalette { id: sysPal; }
            Label {
                text: model.display
                color: sysPal.light

                font.bold: true
                horizontalAlignment: Qt.AlignHCenter
                wrapMode: Text.Wrap

                Layout.maximumWidth: album.width
                Layout.minimumWidth: album.width
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onClicked: gridView.albumSelected(model.files)

                onEntered: {
                    album.hover = true
                    gridView.currentIndex = index
                }
                onExited: album.hover = false
            }
        }
    }
}
