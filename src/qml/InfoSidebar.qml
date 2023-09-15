/* SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Window 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.coreaddons 1.0 as KCA

QQC2.Page {
    id: root
    required property Koko.Exiv2Extractor extractor
    signal closed()
    leftPadding: root.mirrored && vScrollBar.visible ? vScrollBar.width : 0
    rightPadding: !root.mirrored && vScrollBar.visible ? vScrollBar.width : 0
    topPadding: 0
    bottomPadding: 0
    header: QQC2.ToolBar {
        implicitHeight: closeButton.implicitHeight
        leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Heading {
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: leftPadding
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
                level: 2
                text: i18n("Metadata")
            }
            QQC2.ToolButton {
                id: closeButton
                icon.name: "window-close"
                icon.width: Kirigami.Units.iconSizes.sizeForLabels
                icon.height: Kirigami.Units.iconSizes.sizeForLabels
                onClicked: root.closed()
            }
        }
    }
    // QQC2 ScrollView makes it surprisingly difficult to control the
    // content size and implicit size without binding loops or glitches.
    // ScrollView completely ignores the Flickable's implicit size.
    // Using plain Flickable with ScrollBar instead.
    contentItem: InfoDrawerSidebarBase {
        id: content
        extractor: root.extractor
        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: vScrollBar
            parent: content.parent
            anchors.left: parent.contentItem.right
            anchors.top: parent.header.bottom
            anchors.bottom: parent.bottom
        }
    }
    Component.onCompleted: {
        root.contentItem.opacity = 1
    }
    onClosed: {
        root.contentItem.opacity = 0
    }
}
