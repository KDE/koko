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

Item {
    id: albumDelegate
    width: gridView.cellWidth
    height: gridView.cellHeight
    
    Image {
        id: image
        source: model.cover ? model.cover: model.modelData
        anchors.centerIn: parent
        width: gridView.cellWidth - (Kirigami.Units.largeSpacing )
        height: gridView.cellHeight - (Kirigami.Units.largeSpacing )
        
        fillMode: Image.PreserveAspectCrop
    }
    KQA.QImageItem {
        anchors.fill: image
        image: model.thumbnail
    }
    
    Kirigami.BasicListItem {
        visible: isCollection
        label: model.fileCount == 1 ? qsTr(" %1 \n 1 Image").arg(model.display) : qsTr(" %1 \n %2 Images").arg(model.display).arg(model.fileCount);
        reserveSpaceForIcon: false
        width: image.width
        anchors.left: image.left
        anchors.top: image.top
        background: Rectangle {
            anchors.fill: parent
            opacity: 0.7
            color: Kirigami.Theme.backgroundColor
        }
    }
    
    SelectionButton {
        id: selectionButton
        visible: ( albumThumbnailMouseArea.containsMouse || iconMouseArea.containsMouse )
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
            isCollection ? collectionSelected(model.files, model.display): imageSelected(model.index)
            gridView.currentIndex = model.index
        }
    }
    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Space:
                isCollection ? collectionSelected(model.files, model.display): imageSelected(model.index)
                gridView.currentIndex = model.index
                break;
            default:
                break;
        }
    }
}
