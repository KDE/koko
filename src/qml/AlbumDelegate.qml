/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.7
import QtQuick.Controls 2.1 as Controls
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kirigami 2.12 as Kirigami
import org.kde.koko 0.1 as Koko

Item {
    id: albumDelegate
    width: gridView.cellWidth
    height: gridView.cellHeight

    signal clicked(var mouse)
    signal pressAndHold(var mouse)
    signal activated
    property alias containsMouse: albumThumbnailMouseArea.containsMouse
    property QtObject modelData

    Rectangle {
        anchors {
            fill: image
            margins: -1
        }
        radius: 2
        color: Kirigami.Theme.textColor
        opacity: 0.2
        visible: modelData.itemType != Koko.Types.Folder
    }
    KQA.QImageItem {
        id: image
        anchors.centerIn: parent
        width: kokoConfig.iconSize
        height: width
        smooth: true
        image: modelData.thumbnail
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
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
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
        visible: modelData.itemType == Koko.Types.Folder || modelData.itemType == Koko.Types.Album
        verticalAlignment: Text.AlignTop
        padding: Kirigami.Units.smallSpacing
        elide: Text.ElideRight
        maximumLineCount: 4
        wrapMode: Text.WordWrap
        color: Kirigami.Theme.textColor
        text: modelData.display
    }

    Rectangle {
        id: countRect
        anchors {
            bottom: image.bottom
            left: image.left
            right: image.right
        }
        visible: modelData.fileCount && modelData.itemType == Koko.Types.Folder || modelData.itemType == Koko.Types.Album
        height: countLabel.contentHeight + (Kirigami.Units.smallSpacing * 2)
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        opacity: 0.8

        Controls.Label {
            id: countLabel
            padding: Kirigami.Units.smallSpacing
            elide: Text.ElideRight
            maximumLineCount: 4
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
            text: i18np("1 Image", "%1 Images", modelData.fileCount)
        }
    }
    
    SelectionDelegateHighlight {
        id: selectionHighlight
        visible: modelData.selected
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
