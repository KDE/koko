// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.koko

Kirigami.FormEntry {
    id: root

    title: i18nc("@label:listbox", "Color scheme:")

    contentItem: QQC2.ComboBox {
        id: comboBox

        Layout.fillWidth: true
        textRole: "display"
        valueRole: "display"
        model: ColorSchemer.model

        Component.onCompleted: currentIndex = ColorSchemer.indexForCurrentScheme()
        onCurrentValueChanged: ColorSchemer.apply(currentIndex)
    }
}
