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
import QtQuick.Window 2.1

import org.kde.plasma.components 2.0 as PlasmaComponents

ApplicationWindow {
    id: window
//    color: "#192629"

    toolBar: ToolBar {
        RowLayout {
            anchors.fill: parent
            PlasmaComponents.ToolButton {
                iconName: "go-previous"
                text: "Previous"
            }
            PlasmaComponents.ToolButton {
                iconName: "go-next"
                text: "Next"
            }
            // TODO: Add seperator?
            PlasmaComponents.ToolButton {
                iconName: "document-share"
                text: "Share"
            }

            // Spacer
            Item {
                Layout.fillWidth: true
            }
            PlasmaComponents.ToolButton {
                iconName: "view-fullscreen"
                text: "Fullscreen"
                Layout.alignment: Qt.AlignRight

                onClicked: {
                    if (window.visibility == Window.FullScreen)
                        window.visibility = Window.Maximized
                    else
                        window.visibility = Window.FullScreen
                }

            }
        }
    }

    StackView {
        id: view
        initialItem: MainScreen {
            id: mainScreen
            onImageSelected: {
                view.push(imageScreenComponent)
            }
        }
    }

    Component {
        id: imageScreenComponent
        ImageViewingScreen {
            id: imageViewer
        }
    }
}
