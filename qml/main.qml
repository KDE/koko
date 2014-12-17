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
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.koko 0.1 as Koko

MainWindow {
    id: window

    toolBar: ToolBar {
        RowLayout {
            PlasmaComponents.ToolButton {
                iconName: "draw-arrow-back"
                text: "Back"

                onClicked: {
                    view.pop()
                    view.currentItem.focus = true
                }
            }
        }
    }

    leftSidebar: ColumnLayout {
        width: 350

        PlasmaExtras.Heading {
            text: "Navigation"
            font.bold: true
            level: 2
        }

        ExclusiveGroup { id: group; }

        ColumnLayout {
            Layout.fillWidth: true

            PlasmaExtras.Heading {
                text: "Locations"
                font.bold: true
                Layout.fillWidth: true
                level: 4
            }
            PlasmaComponents.ToolButton {
                text: "By Country"
                iconName: "system-search"
                Layout.fillWidth: true
                onClicked: {
                    locationView.group = Koko.ImageLocationModel.Country
                    locationView.focus = true
                    if (locationView.Stack.index != -1) {
                        view.pop(locationView)
                    } else {
                        view.push(locationView)
                    }
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By State"
                iconName: "system-search"
                Layout.fillWidth: true
                onClicked: {
                    locationView.group = Koko.ImageLocationModel.State
                    locationView.focus = true
                    if (locationView.Stack.index != -1) {
                        view.pop(locationView)
                    } else {
                        view.push(locationView)
                    }
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By City"
                iconName: "system-search"
                Layout.fillWidth: true

                onClicked: {
                    locationView.group = Koko.ImageLocationModel.City
                    locationView.focus = true
                    if (locationView.Stack.index != -1) {
                        view.pop(locationView)
                    } else {
                        view.push(locationView)
                    }
                }
                checkable: true
                exclusiveGroup: group
                checked: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            PlasmaExtras.Heading {
                text: "Time"
                font.bold: true
                Layout.fillWidth: true
                level: 4
            }
            PlasmaComponents.ToolButton {
                text: "By Year"
                iconName: "system-search"
                Layout.fillWidth: true
                onClicked: {
                    timeImages.group = Koko.ImageTimeModel.Year
                    timeImages.focus = true
                    if (timeImages.Stack.index != -1) {
                        view.pop(timeImages)
                    } else {
                        view.push(timeImages)
                    }
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By Month"
                iconName: "system-search"
                Layout.fillWidth: true
                onClicked: {
                    timeImages.group = Koko.ImageTimeModel.Month
                    timeImages.focus = true
                    if (timeImages.Stack.index != -1) {
                        view.pop(timeImages)
                    } else {
                        view.push(timeImages)
                    }
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By Week"
                iconName: "system-search"
                Layout.fillWidth: true

                onClicked: {
                    timeImages.group = Koko.ImageTimeModel.Week
                    timeImages.focus = true
                    if (timeImages.Stack.index != -1) {
                        view.pop(timeImages)
                    } else {
                        view.push(timeImages)
                    }
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By Day"
                iconName: "system-search"
                Layout.fillWidth: true

                onClicked: {
                    timeImages.group = Koko.ImageTimeModel.Day
                    timeImages.focus = true
                    if (timeImages.Stack.index != -1) {
                        view.pop(timeImages)
                    } else {
                        view.push(timeImages)
                    }
                }
                checkable: true
                exclusiveGroup: group
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            PlasmaExtras.Heading {
                text: "Path"
                font.bold: true
                Layout.fillWidth: true
                level: 4
            }
            PlasmaComponents.ToolButton {
                text: "By Folder"
                iconName: "system-search"
                Layout.fillWidth: true
                onClicked: {
                    if (view.currentItem != folderImages) {
                        folderImages.focus = true
                        view.push(folderImages)
                    }
                }
                checkable: true
                exclusiveGroup: group
            }
        }
    }

    mainItem: StackView {
        id: view

        delegate: StackViewDelegate {
            pushTransition: StackViewTransition {
                PropertyAnimation {
                    target: enterItem
                    property: "y"
                    from: exitItem.height
                    to: 0
                }
            }
            popTransition: StackViewTransition {
                PropertyAnimation {
                    target: exitItem
                    property: "y"
                    from: 0
                    to: enterItem.height
                }
            }
        }

        Locations {
            id: locationView
            onImagesSelected: {
                imageGrid.model = files
                imageGrid.focus = true
                view.push(imageGrid)
            }
            group: Koko.ImageLocationModel.City
        }

        ImageGrid {
            id: imageGrid
            visible: false
            onImageSelected: {
                imageViewer.filePath = filePath
                imageViewer.currentIndex = index
                imageViewer.model = model
                imageViewer.focus = true

                view.push(imageViewer)
            }
        }

        Viewer {
            id: imageViewer
            visible: false

            onCurrentIndexChanged: imageGrid.index = currentIndex
        }

        TimeImages {
            id: timeImages
            visible: false
            onImagesSelected: {
                imageGrid.model = files
                imageGrid.focus = true
                view.push(imageGrid)
            }
        }

        Folders {
            id: folderImages
            visible: false
            onImagesSelected: {
                imageGrid.model = files
                imageGrid.focus = true
                view.push(imageGrid)
            }
        }

        FirstRun {
            id: firstRun
            visible: false
            progress: kokoProcessor.initialProgress

            Layout.fillWidth: true
            Layout.fillHeight: true

            onFinished: {
                kokoConfig.initialRun = false
                view.finishInitialization();
            }
        }

        Component.onCompleted: {
            if (kokoConfig && kokoConfig.initialRun) {
                push(firstRun)
                leftSidebar.enabled = false
                toolBar.enabled = false
            } else {
                view.finishInitialization();
            }
        }

        Keys.onEscapePressed: {
            view.pop()
            view.currentItem.focus = true
        }

        function finishInitialization() {
            clear()
            push(locationView)
            locationView.focus = true
            leftSidebar.enabled = true
            toolBar.enabled = true
        }
    }

    contentItem.implicitWidth: 1800
    contentItem.implicitHeight: 1000
}
