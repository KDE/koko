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

    signal clicked(var mouse)
    signal pressAndHold(var mouse)
    signal activated
    property alias containsMouse: albumThumbnailMouseArea.containsMouse

    Rectangle {
        anchors {
            fill: image
            margins: -1
        }
        radius: 2
        color: Kirigami.Theme.textColor
        opacity: 0.2
        visible: model.itemType != Koko.Types.Folder
    }
    KQA.QImageItem {
        id: image
        anchors.centerIn: parent
        width: kokoConfig.iconSize
        height: width
        smooth: true
        image: model.thumbnail
        fillMode: KQA.QImageItem.PreserveAspectCrop
    }

    Rectangle {
        anchors {
            top: image.top
            left: image.left
            right: image.right
        }
        visible: textLabel.visible
        width: image.width
        height: textLabel.contentHeight + (Kirigami.Units.smallSpacing * 2)
        color: Kirigami.Theme.viewBackgroundColor
        opacity: 0.8
    }
        
    Controls.Label {
        id: textLabel
        anchors {
            left: image.left
            right: image.right
            top: image.top
            bottom: countRect.visible ? countRect.top : image.bottom
        }
        visible: model.itemType == Koko.Types.Folder || model.itemType == Koko.Types.Album
        verticalAlignment: Text.AlignTop
        padding: Kirigami.Units.smallSpacing
        elide: Text.ElideRight
        maximumLineCount: 4
        wrapMode: Text.WordWrap
        color: Kirigami.Theme.textColor
        text: model.display
    }

    Rectangle {
        id: countRect
        anchors {
            bottom: image.bottom
            left: image.left
            right: image.right
        }
        visible: model.fileCount && model.itemType == Koko.Types.Folder || model.itemType == Koko.Types.Album
        height: countLabel.contentHeight + (Kirigami.Units.smallSpacing * 2)
        color: Kirigami.Theme.viewBackgroundColor
        opacity: 0.8

        Controls.Label {
            id: countLabel
            padding: Kirigami.Units.smallSpacing
            elide: Text.ElideRight
            maximumLineCount: 4
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
            text: i18np("1 Image", "%1 Images", model.fileCount)
        }
    }
    
    SelectionDelegateHighlight {
        id: selectionHighlight
        visible: model.selected
    }

    MouseArea {
        id: albumThumbnailMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onPressAndHold: albumDelegate.pressAndHold(mouse)
        onClicked: albumDelegate.clicked(mouse)
    }
    
    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Space:
                activated();
                break;
            default:
                break;
        }
    }
    
}
