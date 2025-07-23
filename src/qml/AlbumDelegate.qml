/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick
import QtQml.Models
import QtQuick.Controls as Controls
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.kquickcontrolsaddons

T.ItemDelegate {
    id: root

    required property int index
    required property bool selected
    required property var thumbnail
    required property int itemType
    required property string content
    required property int fileCount
    required property string imageurl
    property ItemSelectionModel selectionModel

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    hoverEnabled: true

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

        QImageItem {
            id: image

            anchors.centerIn: parent
            image: root.thumbnail ? root.thumbnail : undefined
            width: root.width - 1
            height: width
            visible: root.thumbnail !== false
            fillMode: QImageItem.PreserveAspectCrop

            Rectangle {
                visible: root.selected
                anchors.fill: parent
                color: "white"
                opacity: 0.4
            }
        }

        Loader {
            active: root.selectionModel && root.selectionModel.hasSelection
            anchors {
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.smallSpacing
                right: parent.right
                rightMargin: Kirigami.Units.smallSpacing
            }

            sourceComponent: Controls.CheckBox {
                onClicked: root.clicked();
                checked: delegate.selected
            }
        }
    }

    background: null

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
                root.clicked();
        }
    }
}
