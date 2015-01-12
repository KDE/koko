/*
 * Copyright (C) 2014-2015 Vishesh Handa <vhanda@kde.org>
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
import org.kde.koko 0.1 as Koko

MainWindow {
    id: window

    toolBar: ToolBar {
        RowLayout {
            PlasmaComponents.ToolButton {
                iconName: "draw-arrow-back"
                text: "Back"
                enabled: view.depth > 1

                onClicked: {
                    view.pop()
                    view.currentItem.focus = true
                }
            }
        }
    }

    leftSidebar: ColumnLayout {
        width: 350

        Heading {
            text: "Navigation"
            font.bold: true
            level: 2
        }

        ExclusiveGroup { id: group; }

        ColumnLayout {
            Layout.fillWidth: true

            Heading {
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
                    view.clear()
                    view.push({
                        item: locationView,
                        properties: { focus: true, group: Koko.ImageLocationModel.Country }
                    })
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By State"
                iconName: "system-search"
                Layout.fillWidth: true
                onClicked: {
                    view.clear()
                    view.push({
                        item: locationView,
                        properties: { focus: true, group: Koko.ImageLocationModel.State }
                    })
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By City"
                iconName: "system-search"
                Layout.fillWidth: true

                onClicked: {
                    view.clear()
                    view.push({
                        item: locationView,
                        properties: { focus: true, group: Koko.ImageLocationModel.City }
                    })
                }
                checkable: true
                exclusiveGroup: group
                checked: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            Heading {
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
                    view.clear()
                    view.push({
                        item: timeImages,
                        properties: { focus: true, group: Koko.ImageTimeModel.Year }
                    })
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By Month"
                iconName: "system-search"
                Layout.fillWidth: true
                onClicked: {
                    view.clear()
                    view.push({
                        item: timeImages,
                        properties: { focus: true, group: Koko.ImageTimeModel.Month }
                    })
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By Week"
                iconName: "system-search"
                Layout.fillWidth: true

                onClicked: {
                    view.clear()
                    view.push({
                        item: timeImages,
                        properties: { focus: true, group: Koko.ImageTimeModel.Week }
                    })
                }
                checkable: true
                exclusiveGroup: group
            }
            PlasmaComponents.ToolButton {
                text: "By Day"
                iconName: "system-search"
                Layout.fillWidth: true

                onClicked: {
                    view.clear()
                    view.push({
                        item: timeImages,
                        properties: { focus: true, group: Koko.ImageTimeModel.Day }
                    })
                }
                checkable: true
                exclusiveGroup: group
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            Heading {
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
                    view.clear()
                    view.push({
                        item: folderImages,
                        properties: { focus: true }
                    })
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

        Component {
            id: locationView
            Locations {
                onImagesSelected: {
                    view.push({
                        item: imageGrid,
                        properties: { focus: true, model: files }
                    })
                }
                group: Koko.ImageLocationModel.City
            }
        }

        Component {
            id: imageGrid
            ImageGrid {
                onImageSelected: {
                    view.push({
                        item: imageViewer,
                        properties: { focus: true,
                                      model: model,
                                      filePath: filePath,
                                      currentIndex: index }
                    })
                }
            }
        }

        Component {
            id: imageViewer
            ImageViewer {
                // This is done so that the current selected item is correct
                // if the user selects another item when in the ImageView (left/right keys)
                // FIXME: Doesn't work with components
                // onCurrentIndexChanged: imageGrid.index = currentIndex
            }
        }

        Component {
            id: timeImages
            TimeImages {
                onImagesSelected: {
                    view.push({
                        item: imageGrid,
                        properties: { focus: true, model: files }
                    })
                }
            }
        }

        Component {
            id: folderImages
            Folders {
                onImagesSelected: {
                    view.push({
                        item: imageGrid,
                        properties: { focus: true, model: files }
                    })
                }
            }
        }

        Component {
            id: firstRun
            FirstRun {
                visible: false
                progress: kokoProcessor.initialProgress
                numFiles: kokoProcessor.numFiles

                Layout.fillWidth: true
                Layout.fillHeight: true

                onFinished: {
                    kokoConfig.initialRun = false
                    view.finishInitialization();
                }
            }
        }

        Component {
            id: balooDisabled
            BalooDisabled {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        Component.onCompleted: {
            if (kokoConfig) {
                if (kokoConfig.balooEnabled == false) {
                    push({
                        item: balooDisabled,
                        immediate: true,
                        replace: true
                    })
                    leftSidebar.visible = false
                    toolBar.visible = false
                    return;
                }
                else if (kokoConfig.initialRun) {
                    push({
                        item: firstRun,
                        immediate: true,
                        replace: true
                    })
                    leftSidebar.enabled = false
                    toolBar.enabled = false
                    return;
                }
            }

            view.finishInitialization();
        }

        Keys.onEscapePressed: {
            view.pop()
            view.currentItem.focus = true
        }

        function finishInitialization() {
            clear()
            leftSidebar.enabled = true
            toolBar.enabled = true

            push({
                item: locationView,
                replace: true,
                properties: { focus: true }
            })
        }
    }

    contentItem.implicitWidth: 1800
    contentItem.implicitHeight: 1000
}
