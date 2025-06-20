/* SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQml
import QtQuick.Window
import QtQuick.Templates as T
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.koko.private as KokoPrivate

Kirigami.OverlayDrawer {
    id: root

    required property Koko.Exiv2Extractor extractor
    required property Koko.PhotosApplication application

    drawerOpen: false
    edge: Qt.application.layoutDirection == Qt.RightToLeft ? Qt.LeftEdge : Qt.RightEdge
    handleVisible: false

    leftPadding: root.mirrored && vScrollBar.visible ? vScrollBar.width : 0
    rightPadding: !root.mirrored && vScrollBar.visible ? vScrollBar.width : 0
    topPadding: Math.ceil(header.implicitHeight) + header.y
    bottomPadding: 0

    Kirigami.Heading {
        id: header

        parent: content.parent
        z: 1
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignVCenter
        level: 2
        text: i18n("Metadata")

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Kirigami.Units.largeSpacing
            topMargin: Kirigami.Units.largeSpacing
        }
    }

    // QQC2 ScrollView makes it surprisingly difficult to control the
    // content size and implicit size without binding loops or glitches.
    // ScrollView completely ignores the Flickable's implicit size.
    // Using plain Flickable with ScrollBar instead.
    contentItem: InfoDrawerSidebarBase {
        id: content

        extractor: root.extractor
        application: root.application

        topMargin: 0
        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: vScrollBar

            parent: content.parent

            anchors {
                left: parent.contentItem.right
                top: parent.top
                bottom: parent.bottom
            }
        }
    }
    Component.onCompleted: root.open()
}
