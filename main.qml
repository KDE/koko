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

ApplicationWindow {
    id: window
    color: "#192629"

    toolBar: ToolBar {
        RowLayout {
            anchors.fill: parent
            Button {
                iconName: "go-previous"
                text: "Previous"
            }
            Button {
                iconName: "go-next"
                text: "Next"
            }
            // TODO: Add seperator?
            Button {
                iconName: "document-share"
                text: "Share"
            }

            // Spacer
            Item {
                Layout.fillWidth: true
            }
            Button {
                iconName: "view-fullscreen"
                text: "Fullscreen"
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    RowLayout {
        anchors.fill: parent

        Navigation {
            id: navigation
            Layout.minimumWidth: 600
            Layout.maximumWidth: 600

            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
        }

        /*
        ImageGrid {
            Layout.alignment: Qt.AlignTop | Qt.AlignCenter
            Layout.maximumWidth: 600
            id: images
        }
        */

        ColumnLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.maximumWidth: 500
            Layout.fillHeight: true
            Actions {
                id: actions
            }

            Rectangle {
                color: "#31363B"
                anchors.fill: parent
                z: -1
            }
        }
    }
}
