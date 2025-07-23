// SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.photos.thumbnails as PhotosThumbnails
import org.kde.kquickcontrolsaddons

Controls.ItemDelegate {
    id: root

    required property int index
    required property bool selected
    required property int itemType
    required property string content
    required property int fileCount
    required property string imageurl
    required property var item

    property alias thumbnailPriority: image.priority

    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    leftInset: Kirigami.Units.smallSpacing
    rightInset: Kirigami.Units.smallSpacing
    topInset: Kirigami.Units.smallSpacing
    bottomInset: Kirigami.Units.smallSpacing

    readonly property color stateIndicatorColor: if (root.activeFocus || root.hovered || root.selected) {
        return Kirigami.Theme.highlightColor;
    } else {
        return "transparent";
    }

    readonly property real stateIndicatorOpacity: if (root.activeFocus || root.hovered) {
        return root.selected ? 1 : 0.3;
    } else if (root.selected) {
        return 0.7
    } else {
        return 0;
    }

    width: gridView.cellWidth
    height: gridView.cellHeight

    function refresh(): void {
        // HACK: force refresh image after it was edited.
        const old = image.image;
        image.image = undefined;
        image.image = old;
    }

    contentItem: Item {
        Kirigami.Icon {
            id: placeholderImage

            anchors.centerIn: parent
            source: root.thumbnail === false ? "chronometer-symbolic" : ''
            width: Kirigami.Units.iconSizes.large
            height: width
            visible: root.thumbnail === false
        }

        PhotosThumbnails.ThumbnailItem {
            id: image
            anchors.centerIn: parent

            width: root.width - 1
            height: width

            fileItem: root.item
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
            visible: root.itemType == Koko.AbstractImageModel.Folder || root.itemType == Koko.AbstractImageModel.Collection
            verticalAlignment: Text.AlignTop
            padding: Kirigami.Units.smallSpacing
            elide: Text.ElideRight
            maximumLineCount: 4
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
            text: root.content
        }

        Rectangle {
            id: countRect
            anchors {
                bottom: image.bottom
                left: image.left
                right: image.right
            }
            visible: root.fileCount && root.itemType == Koko.AbstractImageModel.Folder || root.itemType == Koko.AbstractImageModel.Collection
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
                text: i18np("1 Image", "%1 Images", root.fileCount)
            }
        }
    }


    background: Rectangle {
        radius: Kirigami.Settings.isMobile ? Kirigami.Units.smallSpacing : 3
        color: stateIndicatorColor
        opacity: stateIndicatorOpacity
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
                root.clicked();
        }
    }
}
