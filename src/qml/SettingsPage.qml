/*
 * SPDX-FileCopyrightText: (C) 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.5
import org.kde.kirigami 2.18 as Kirigami

Kirigami.CategorizedSettings {
    actions: [
        Kirigami.SettingAction {
            text: i18n("General")
            icon.name: "koko"
            page: "qrc:/qml/GeneralSettingsPage.qml"
        },
        Kirigami.SettingAction {
            text: i18n("About Koko")
            icon.name: "help-about"
            page: "qrc:/qml/AboutPage.qml"
        }
    ]
}

