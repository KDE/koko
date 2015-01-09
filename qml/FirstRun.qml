/*
 * Copyright (C) 2014-2015  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1 as QtControls

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    signal finished()
    property alias progress: progressBar.value
    property int numFiles: 0

    ColumnLayout {
        anchors.centerIn: parent

        PlasmaExtras.Heading {
            text: "Koko"
            font.bold: true
            font.pointSize: 100
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
        PlasmaExtras.Heading {
            text: "By KDE"
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            level: 3
        }


        QtControls.ProgressBar {
            id: progressBar
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true

            maximumValue: 1.0
            minimumValue: 0.0

            onValueChanged: {
                if (value == maximumValue) {
                    finished()
                }
            }
        }

        PlasmaComponents.Label {
            id: statusLabel
            text: numFiles == 0 ? "No Image Files Found" : "Initializing..."
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
    }
}
