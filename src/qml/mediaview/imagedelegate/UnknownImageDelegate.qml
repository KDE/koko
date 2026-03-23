/*
 *  SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick

import org.kde.kirigami as Kirigami

BaseImageDelegate {
    id: root

    loaded: false
    loading: false

    enabled: false

    sourceWidth: placeholderMessage.implicitWidth
    sourceHeight: placeholderMessage.implicitHeight

    Kirigami.PlaceholderMessage {
        id: placeholderMessage
        anchors.centerIn: parent

        Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
        Kirigami.Theme.inherit: false

        icon.name: "error-symbolic"
        text: xi18nc("@info:usagetip", "This media could not be loaded");
        explanation: xi18nc("@info:usagetip", "Unknown file type for %1", root.source);
    }
}
