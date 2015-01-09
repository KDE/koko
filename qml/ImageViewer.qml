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

import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0 as QtControls

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: root
    clip: true

    /**
     * An optional model which contains all the Images. This is used
     * to change the index during Key Navigation
     */
    property var model
    property int currentIndex

    Rectangle {
        color: "#646464"
        anchors.fill: parent
        z: -1
    }

    property string filePath
    onFilePathChanged: {
        slider.value = 1.0
        img.rotation = 0
    }

    ColumnLayout {
        anchors.fill: parent
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: img.width
            contentHeight: img.height
            boundsBehavior: Flickable.StopAtBounds
            Image {
                id: img
                source: root.filePath
                fillMode: Image.PreserveAspectFit

                width: flick.width * artificalScale
                height: flick.height * artificalScale
                mipmap: true

                /**
                 * We cannot use the Item.scale property as that doesn't change
                 * the width/height of the Image since it is applied later.
                 * Also, we don't get any of the fancy cubic scaling.
                 */
                property double artificalScale: 1.0
            }
        }

        ClipRectangle {
            id: clipRect
            source: img
            visible: false
        }

        QtControls.ToolBar {
            Layout.fillWidth: true

            RowLayout {
                anchors.fill: parent
                PlasmaComponents.ToolButton {
                    iconName: "object-rotate-left"
                    onClicked: img.rotation = img.rotation - 90
                }
                PlasmaComponents.ToolButton {
                    iconName: "object-rotate-right"
                    onClicked: img.rotation = img.rotation + 90
                }
                PlasmaComponents.ToolButton {
                    iconName: "transform-crop"
                    onClicked: {
                        clipRect.visible = !clipRect.visible
                        // Marking the button as in use. It's an ugly way
                        flat = !clipRect.visible
                        // Reset the clip rectangle?
                    }
                }
                PlasmaComponents.ToolButton {
                    iconName: "trash-empty"
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // Zoom
                QtControls.Button {
                    text: "Fit"
                    // FIXME: Automatically detect the best zoom level!!
                    onClicked: slider.value = 1.0
                }
                QtControls.Button {
                    text: "100%"
                    onClicked: slider.value = 1.0
                }
                QtControls.ToolButton {
                    iconName: "file-zoom-out"
                    onClicked: slider.value = slider.value - 1.0
                }
                QtControls.Slider {
                    id: slider
                    minimumValue: 1.0
                    maximumValue: 9.99
                    value: 1.0

                    Layout.alignment: Qt.AlignRight

                    onValueChanged: {
                        img.artificalScale = value
                    }
                }
                QtControls.ToolButton {
                    iconName: "file-zoom-in"
                    onClicked: slider.value = slider.value + 1.0
                }
                QtControls.Label {
                    text: Math.floor(img.artificalScale * 100) + "%"
                }
            }
        }
    }

    Keys.onRightPressed: {
        currentIndex = Math.min(model.length - 1, currentIndex + 1)
        filePath = model[currentIndex]
    }
    Keys.onLeftPressed: {
        currentIndex = Math.max(0, currentIndex - 1)
        filePath = model[currentIndex]
    }
}
