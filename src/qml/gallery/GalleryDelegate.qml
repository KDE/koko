/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2026 Gustavo Kazuhiko Rodrigues Mitamura <gustavokrm@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick
import QtQuick.Controls as Controls

import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons

import org.kde.koko as Koko
import org.kde.photos.thumbnails as KokoThumbnails

Kirigami.AbstractCard {
    id: root

    required property int index
    required property string name
    required property var fileItem
    required property int itemType
    required property int fileCount
    required property bool selected
    required property url url

    required property bool isCut

    required property bool selectionMode
    required property bool fileNamesEnabled
    required property FontMetrics fontMetrics

    property alias thumbnailPriority: image.priority

    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    leftInset: Kirigami.Units.smallSpacing
    rightInset: Kirigami.Units.smallSpacing
    topInset: Kirigami.Units.smallSpacing
    bottomInset: Kirigami.Units.smallSpacing

    readonly property bool showFileNames: root.fileNamesEnabled ? enabled : root.itemType === Koko.AbstractGalleryModel.Folder || root.itemType === Koko.AbstractGalleryModel.Collection

    readonly property int thumbSize: if (countLabel.visible && (root.itemType === Koko.AbstractGalleryModel.Collection && !root.fileNamesEnabled)) {
        return Koko.Config.iconSize - fontMetrics.height * 3;
    } else if (countLabel.visible) {
        return Koko.Config.iconSize - fontMetrics.height;
    } else {
        return Koko.Config.iconSize;
    }

    readonly property int fileNamesHeight: countLabel.visible ? fontMetrics.height * 3 : fontMetrics.height * 2

    width: gridView.cellWidth
    height: gridView.cellHeight
    showClickFeedback: true
    hoverEnabled: true

    Controls.ToolTip.text: name
    Controls.ToolTip.visible: hovered && name.length !== 0 && ((itemType === Koko.AbstractGalleryModel.Media || itemType === Koko.AbstractGalleryModel.Folder) && textLabel.truncated) || !root.showFileNames
    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

    header: Item {
        implicitHeight: root.thumbSize - Kirigami.Units.smallSpacing
        clip: true

        Kirigami.Icon {
            id: placeholderImage
            anchors.centerIn: parent
            source: "chronometer-symbolic"
            width: Kirigami.Units.iconSizes.large
            height: width
            visible: !image.thumbnailReady
        }

        KokoThumbnails.ThumbnailItem {
            id: image
            anchors.centerIn: parent

            width: Koko.Config.iconSize
            height: width

            opacity: root.isCut ? 0.6 : 1

            fileItem: root.fileItem
        }
    }

    footer: Column {
        id: footer
        z: 2        

        height: root.fileNamesHeight

        Item {
            width: parent.width
            implicitHeight: textLabel.visible ? textLabel.contentHeight : 0
            visible: true

            Rectangle {
                anchors {
                    left: textLabel.left
                    right: textLabel.right
                }
                visible: !root.fileNamesEnabled && (root.itemType === Koko.AbstractGalleryModel.Folder) || Kirigami.Settings.isMobile && root.selected
                height: textLabel.contentHeight + Kirigami.Units.smallSpacing
                color: Kirigami.Theme.backgroundColor
                opacity: 0.8
            }

            Controls.Label {
                id: textLabel
                width: parent.width
                text: root.name
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                visible: root.showFileNames || Kirigami.Settings.isMobile && root.selected
                maximumLineCount: 2
                verticalAlignment: Text.AlignTop
            }
        }

        Controls.Label {
            id: countLabel
            visible: (root.itemType === Koko.AbstractGalleryModel.Folder || root.itemType === Koko.AbstractGalleryModel.Collection) && root.fileCount > 0
            width: parent.width
            text: i18np("1 item", "%1 items", root.fileCount)
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
        }
    }
}
