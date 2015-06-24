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

import org.kde.koko 0.1 as Koko

ScrollView {
    id: root
    property alias model: view.model
    property alias index: view.currentIndex
    signal imageSelected(string filePath, int index)

    // Without this the GridView will not get focus
    // See QTBUG-31976
    flickableItem.interactive: true

    AutomaticSpacingGrid {
        id: view
        anchors.fill: parent

        focus: true
        minRowSpacing: 5
        minColumnSpacing: 5
        cacheBuffer: 10000

        delegate: Item {
            width: view.cellWidth
            height: view.cellHeight

            Image {
                source: model.modelData
                asynchronous: true
                fillMode: Image.PreserveAspectCrop

                width: 300
                height: 300
                sourceSize: Qt.size(300, 300)
                anchors.centerIn: parent

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: root.imageSelected(model.modelData, model.index)
                    onEntered: view.currentIndex = index
                }

                SystemPalette { id: sysPal; }
                Rectangle {
                    id: borderRect
                    anchors.fill: parent
                    color: "#00000000"
                    radius: 2

                    antialiasing: true
                    border.color: view.currentIndex == index ? sysPal.highlight : "grey"
                    border.width: view.currentIndex == index ? 5 : 1
                }
            }

            Keys.onEnterPressed: root.imageSelected(model.modelData, model.index)
            Keys.onReturnPressed: root.imageSelected(model.modelData, model.index)
        }
    }

    function positionViewAtIndex(index, mode) {
        view.positionViewAtIndex(index, mode)
    }
}
