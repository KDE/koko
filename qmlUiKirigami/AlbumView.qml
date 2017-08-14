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
            when: model.hasSelectedImages && Kirigami.Settings.isMobile
        }
    ]

    actions {
        main: Kirigami.Action {
                iconName: "edit-select-none"
                text: i18n("Deselect All")
                tooltip: i18n("De-selects all the selected images")
                enabled: model.hasSelectedImages
                visible: model.hasSelectedImages && Kirigami.Settings.isMobile
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

    leftPadding: (page.width - Math.floor(page.width / gridView.cellWidth) * gridView.cellWidth)/2
    rightPadding: leftPadding
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

        cellWidth: Kirigami.Units.iconSizes.enormous + Kirigami.Units.smallSpacing * 2
        cellHeight: cellWidth
        
        highlight: Rectangle { color: Kirigami.Theme.highlightColor}
        
        delegate: AlbumDelegate {}
        
        Kirigami.Label {
            anchors.centerIn: parent
            text: i18n("No Images Found")
            visible: gridView.count == 0
            font.pointSize: Kirigami.Units.gridUnit * 1
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
