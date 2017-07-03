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
    
    contextualActions: [
        Kirigami.Action {
            text: i18n("Select All")
            enabled: model.containImages
            onTriggered: model.selectAll()
        },
        Kirigami.Action {
            text: i18n("Deselect All")
            enabled: model.containImages
            onTriggered: model.clearSelections()
        },
        Kirigami.Action {
            text: i18n("Delete Selection")
            enabled: model.hasSelectedImages
        }
        
    ]

    GridView {
        id: gridView
        
        property int iconSize: Kirigami.Units.iconSizes.enormous
        keyNavigationEnabled: true
        
        cellWidth: width / Math.floor(width / (iconSize + Kirigami.Units.largeSpacing*2))
        cellHeight: iconSize + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing*2
        
        highlight: Rectangle { color: Kirigami.Theme.highlightColor}
        
        delegate: AlbumDelegate {}
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
    
    Koko.SortModel {
        id: sortedListModel
    }
    Koko.ImageListModel {
        id: imageListModel
    }
    Koko.ImageFolderModel {
        id: imageFolderModel
    }

    onCollectionSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": cover})
    onFolderSelected: pageStack.push( Qt.resolvedUrl("AlbumView.qml"), { "model": selectedModel, "title": cover})
    onImageSelected: {
        currentImage.model = model
        currentImage.index = currentIndex
        imageViewer.state = "open";
    }
    
}
