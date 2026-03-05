/*
 *  SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents

import org.kde.koko as Koko

KirigamiComponents.ConvergentContextMenu {
    id: root

    //property alias urls: fileMenuActions.urls

    property list<Kirigami.Action> galleryActions

    default property list<Kirigami.Action> actions: galleryActions

    headerContentItem: Kirigami.Heading {
        level: 2
        Layout.fillWidth: true
        //text: urls.length === 1 ? urls[0] : i18np("%1 item", "%1 items", urls.length);
        text: "Foo"
        wrapMode: Text.WordWrap
    }
}
