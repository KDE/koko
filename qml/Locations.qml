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
import org.kde.plasma.extras 2.0 as PlasmaExtras

ScrollView {
    id: root
    signal imagesSelected(var files)
    property alias group: imageLocationsModel.group

    // Without this the GridView will not get focus
    // See QTBUG-31976
    flickableItem.interactive: true

    AlbumView {
        id: view
        anchors.fill: parent
        anchors.topMargin: 20
        focus: true

        model: Koko.SortModel {
            sourceModel: Koko.ImageLocationModel {
                id: imageLocationsModel
            }
        }

        onAlbumSelected: root.imagesSelected(files)

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: {
                root.focus = true
                mouse.accepted = false
            }
        }

        PlasmaExtras.Heading {
            text: "No Images Found"
            visible: view.count == 0
            level: 3

            anchors.centerIn: view
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
        }
    }

    onGroupChanged: view.calculateSpacing()
}
