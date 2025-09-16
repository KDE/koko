/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.photos.thumbnails as KokoThumbnails
import org.kde.kquickcontrolsaddons

Controls.ItemDelegate {
    id: root

    required property int index
    required property var fileItem
    required property url url

    property alias thumbnailPriority: image.priority

    leftPadding: Kirigami.Units.gridUnit
    rightPadding: Kirigami.Units.gridUnit
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    leftInset: Kirigami.Units.smallSpacing
    rightInset: Kirigami.Units.smallSpacing
    topInset: Kirigami.Units.smallSpacing
    bottomInset: Kirigami.Units.smallSpacing

    contentItem: Item {

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

            fileItem: root.fileItem
        }
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
                root.clicked();
        }
    }
}
