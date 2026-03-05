/*
 *  SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents

KirigamiComponents.ConvergentContextMenu {
    id: root

    property alias titleText: title.text

    property list<Kirigami.Action> galleryActions

    default property list<Kirigami.Action> actions: galleryActions

    headerContentItem: Kirigami.Heading {
        id: title
        Layout.fillWidth: true

        level: 2
        maximumLineCount: 1
        elide: Text.ElideMiddle
    }
}
