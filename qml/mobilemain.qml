/*
 * Copyright (C) 2015 Vishesh Handa <vhanda@kde.org>
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

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.koko 0.1 as Koko

MobileMainWindow {
    id: mainWindow
    width: 750
    height: 1100

    toolBar: ToolBar {
        RowLayout {
            PlasmaComponents.ToolButton {
                iconName: "format-justify-fill"
                onClicked: mainWindow.toggleSidebar();
            }
        }
    }

    SystemPalette { id: sysPal; }

    sidebar: ColumnLayout {
        spacing: 0
        Heading {
            text: "Navigation"
            font.bold: true
            level: 2
        }

        ColumnLayout {
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
                    mainWindow.toggleSidebar();
                }
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
                    mainWindow.toggleSidebar();
                }
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
                    mainWindow.toggleSidebar();
                }
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
                    mainWindow.toggleSidebar();
                }
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
                    mainWindow.toggleSidebar();
                }
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
                    mainWindow.toggleSidebar();
                }
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
                    mainWindow.toggleSidebar();
                }
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
                    mainWindow.toggleSidebar();
                }
            }
        }

        Item {
            Layout.fillHeight: true
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
                        item: imageBrowser,
                        properties: { focus: true,
                                      model: model,
                                      currentIndex: index }
                    })
                }
            }
        }

        Component {
            id: imageBrowser
            ImageBrowser {
                objectName: "imageViewer"
                imageWidth: mainWindow.width
                imageHeight: mainWindow.height
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

        Component.onCompleted: {
            if (kokoConfig) {
                if (kokoConfig.initialRun) {
                    push({
                        item: firstRun,
                        immediate: true,
                        replace: true
                    })
                    return;
                }
            }

            finishInitialization();
        }

        function finishInitialization() {
            clear();
            push({
                item: locationView,
                replace: true,
                properties: { focus: true }
            })

        }
    }

}

