/*
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
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

import QtQuick 2.7
import QtQuick.Controls 2.1 as Controls

import org.kde.kirigami 2.1 as Kirigami
import org.kde.koko 0.1 as Koko

Kirigami.ScrollablePage {
    id: page
    
    property alias model: gridView.model
    signal collectionSelected(QtObject selectedModel, string cover)
    signal imageSelected(int currentIndex)
    signal folderSelected(QtObject selectedModel, string cover)
    
    keyboardNavigationEnabled: true
    focus: true

    states: [
        State {
            name: "browsing"
            when: !model.hasSelectedImages
        },
        State {
            name: "selecting"
            when: model.hasSelectedImages && Kirigami.Settings.tabletMode
        }
    ]

    actions {
        main: Kirigami.Action {
            iconName: "edit-select-none"
            text: i18n("Deselect All")
            tooltip: i18n("De-selects all the selected images")
            enabled: model.hasSelectedImages
            visible: model.hasSelectedImages && Kirigami.Settings.tabletMode
            onTriggered: model.clearSelections()
        }
        contextualActions: [
            Kirigami.Action {
                iconName: "edit-select-all"
                text: i18n("Select All")
                tooltip: i18n("Selects all the images in the current view")
                enabled: model.containImages
                onTriggered: model.selectAll()
            },
            Kirigami.Action {
                iconName: "edit-select-none"
                text: i18n("Deselect All")
                tooltip: i18n("De-selects all the selected images")
                enabled: model.hasSelectedImages
                onTriggered: model.clearSelections()
            },
            Kirigami.Action {
                iconName: "emblem-shared-symbolic"
                text: i18n("Share")
                tooltip: i18n("Share the selected images")
                enabled: model.hasSelectedImages
                onTriggered: {
                    shareMenu.open();
                    shareMenu.inputData = {
                        "urls": model.selectedImages(),
                        "mimeType": "image/"
                    }
                }
            },
            Kirigami.Action {
                iconName: "group-delete"
                text: i18n("Delete Selection")
                tooltip: i18n("Move selected items to trash")
                enabled: model.hasSelectedImages
                onTriggered: model.deleteSelection()
            }
            
        ]
    }

    background: Rectangle {
        color: Kirigami.Theme.viewBackgroundColor
    }

    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Escape:
                gridView.model.clearSelections()
                break;
            default:
                break;
        }
    }

    ShareDialog {
        id: shareMenu

        inputData: {
            "urls": [],
            "mimeType": ["image/"]
        }
        onFinished: {
            if (error==0 && output.url !== "") {
                console.assert(output.url !== undefined);
                var resultUrl = output.url;
                console.log("Received", resultUrl)
                notificationManager.showNotification( true, resultUrl);
                clipboard.content = resultUrl;
            } else {
                notificationManager.showNotification( false);
            }
        }
    }  

    GridView {
        id: gridView
        //FIXME: right now if those two objects are out of this, the whole page breaks
        Koko.SortModel {
            id: sortedListModel
        }
        Koko.ImageFolderModel {
            id: imageFolderModel
        }

        keyNavigationEnabled: true

        property real widthToApproximate: (applicationWindow().wideScreen ? applicationWindow().pageStack.defaultColumnWidth : page.width) - (1||Kirigami.Settings.tabletMode ? Kirigami.Units.gridUnit : 0)

        cellWidth: Math.floor(width/Math.floor(width/(kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2)))

        cellHeight: kokoConfig.iconSize + Kirigami.Units.largeSpacing * 2

        highlightMoveDuration: 0
        highlight: Item {
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
                border.color: Kirigami.Theme.highlightColor
                radius: 2
            }
        }
        
        delegate: AlbumDelegate {}
        
        Controls.Label {
            anchors.centerIn: parent
            text: i18n("No Images Found")
            visible: gridView.count == 0
            font.pixelSize: Kirigami.Units.gridUnit * 1
        }
    }
    
    onCollectionSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": i18n(cover)})
    onFolderSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": i18n(cover)})
    onImageSelected: {
        currentImage.model = model.sourceModel
        currentImage.index = currentIndex
        applicationWindow().pageStack.layers.push(imageViewerComponent);
    }
}
