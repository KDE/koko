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
    property string currentFilePath: view.currentItem && view.currentItem.filePath ? view.currentItem.filePath : ""

    toolBar: ToolBar {
        RowLayout {
            PlasmaComponents.ToolButton {
                iconName: "format-justify-fill"
                onClicked: window.toggleLeftSidebar();
            }

            PlasmaComponents.ToolButton {
                iconName: "draw-arrow-up"
                text: "Up"
                enabled: view.depth > 1

                onClicked: goUp();
            }

            //
            // Navigation
            //
            PlasmaComponents.ToolButton {
                iconName: "draw-arrow-back"
                text: "Previous"
                enabled: view.currentItem && view.currentItem.objectName == "imageViewer" && view.currentItem.hasPreviousImage()

                onClicked: goBack();
            }
            PlasmaComponents.ToolButton {
                iconName: "draw-arrow-forward"
                text: "Next"
                enabled: view.currentItem && view.currentItem.objectName == "imageViewer" && view.currentItem.hasNextImage()

                onClicked: goForward();
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
        focus: true

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
                objectName: "imageViewer"
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
                finished: kokoProcessor.finished

                Layout.fillWidth: true
                Layout.fillHeight: true

                Connections {
                    target: kokoProcessor
                    onFinishedChanged: {
                        kokoConfig.initialRun = false
                        view.finishInitialization();
                    }
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

        Keys.onPressed: {
            if (event.key == Qt.Key_Escape || event.key == Qt.Key_Backspace) {
                goUp();
            }
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

    function goUp() {
        if (view.currentItem.objectName == "imageViewer") {
            // This is being done so that if the user changes the image in the ImageViewer
            // using the left/right keys, then when they go back to the ImageGrid
            // the correct image is selected
            var ci = view.currentItem.currentIndex
            view.pop()
            view.currentItem.index = ci
            view.currentItem.positionViewAtIndex(ci, GridView.Center)
        } else {
            view.pop()
        }
        view.currentItem.focus = true
    }

    function goBack() {
        view.currentItem.previousImage();
    }
    function goForward() {
        view.currentItem.nextImage();
    }

    contentItem.implicitWidth: 1800
    contentItem.implicitHeight: 1000
}
