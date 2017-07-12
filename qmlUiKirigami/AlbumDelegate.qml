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
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kirigami 2.1 as Kirigami
import org.kde.koko 0.1 as Koko

Item {
    id: albumDelegate
    width: gridView.cellWidth
    height: gridView.cellHeight
    
    KQA.QImageItem {
        id: image
        anchors.centerIn: parent
        width: gridView.cellWidth - (Kirigami.Units.smallSpacing * 2 )
        height: width
        smooth: true
        image: model.thumbnail
        fillMode: KQA.QImageItem.PreserveAspectCrop
    }

    Rectangle {
        visible: model.itemType == Koko.Types.Folder || model.itemType == Koko.Types.Album
        width: image.width
        height: textLabel.contentHeight + (Kirigami.Units.smallSpacing * 2)
        color: Kirigami.Theme.viewBackgroundColor
        anchors.top: image.top
        anchors.left: image.left
        opacity: 0.8
        
        Controls.Label {
            id: textLabel
            anchors.fill: parent
            padding: Kirigami.Units.smallSpacing
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
            text: model.fileCount
                      ? i18np("%2 \n 1 Image", "%2 \n %1 Images", model.fileCount, model.display)
                      : model.display
        }
    }
    
    SelectionButton {
        id: selectionButton
        visible: ( albumThumbnailMouseArea.containsMouse || iconMouseArea.containsMouse ) && !(model.itemType == Koko.Types.Folder || model.itemType == Koko.Types.Album)
    }
    
    SelectionDelegateHighlight {
        id: selectionHighlight
        visible: model.selected
    }
    
    MouseArea {
        id: albumThumbnailMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if ((mouse.modifiers & Qt.ControlModifier ) && (model.itemType == Koko.Types.Image)) {
                gridView.model.toggleSelected(model.index)
            } else {
                activate();
            }
        }
    }
    
    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Space:
                activate();
                break;
            default:
                break;
        }
    }
    
    function activate( ) {
        gridView.model.clearSelections()
        gridView.currentIndex = model.index;
        switch( model.itemType) {
            case Koko.Types.Album: {
                imageListModel.query = imageListModel.queryForIndex( model.sourceIndex)
                sortedListModel.sourceModel = imageListModel
                collectionSelected( sortedListModel, model.display)
                break;
            }
            case Koko.Types.Folder: {
                imageFolderModel.url = model.imageurl
                sortedListModel.sourceModel = imageFolderModel
                folderSelected( sortedListModel, model.display)
                break;
            }
            case Koko.Types.Image: {
                imageSelected( model.sourceIndex)
                break;
            }
            default: {
                console.log("Unknown")
                break;
            }
        }
    }
}
