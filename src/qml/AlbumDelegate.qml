/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.7
import QtQuick.Controls 2.14 as Controls
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kirigami 2.12 as Kirigami
import org.kde.koko 0.1 as Koko

Controls.ItemDelegate {
    id: albumDelegate
    width: gridView.cellWidth
    height: gridView.cellHeight

    signal clicked(var mouse)
    signal pressAndHold(var mouse)
    signal activated
    property alias containsMouse: albumThumbnailMouseArea.containsMouse
    property QtObject modelData
    property bool isInAlbum: false
    function refresh() {
        // HACK: force refresh image after it was edited.
        const old = image.image;
        image.image = undefined;
        image.image = old;
    }

    Rectangle {
        anchors.centerIn: image
        width: image.paintedWidth + (albumDelegate.hovered && !albumDelegate.pressed ? Kirigami.Units.gridUnit : Math.round(Kirigami.Units.gridUnit * 0.5))
        height: image.paintedHeight + (albumDelegate.hovered && !albumDelegate.pressed ? Kirigami.Units.gridUnit : Math.round(Kirigami.Units.gridUnit * 0.5))
        color: albumDelegate.highlighted || (albumDelegate.pressed && !albumDelegate.checked && !albumDelegate.sectionDelegate) || modelData.selected ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
        visible: isInAlbum && (albumDelegate.ListView.view ? albumDelegate.ListView.view.highlight === null : true)
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.highlightColor
            opacity: isInAlbum && albumDelegate.hovered && !albumDelegate.pressed ? 0.4 : 0
            radius: Kirigami.Units.largeSpacing
        }
        radius: Kirigami.Units.largeSpacing
    }

    SelectionButton {
        id: selectionButton
        opacity: delegate.containsMouse || (isInAlbum && page.state === "selecting")
        visible: isInAlbum && !(model.itemType === Koko.Types.Folder || model.itemType === Koko.Types.Album)

        anchors {
            top: image.top
            left: image.left
            leftMargin: Math.round((image.width - image.paintedWidth) / 2 - selectionButton.width / 2)
            topMargin: Math.round((image.height - image.paintedHeight) / 2 - selectionButton.height / 2)
        }

        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    KQA.QImageItem {
        id: image
        anchors.centerIn: parent
        width: kokoConfig.iconSize
        height: width
        smooth: true
        image: modelData.thumbnail
        fillMode: KQA.QImageItem.PreserveAspectFit
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

    background: null
}
