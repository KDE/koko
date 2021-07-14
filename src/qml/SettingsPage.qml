/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Layouts 1.3

import org.kde.kirigami 2.17 as Kirigami

Kirigami.CategorizedSettings {
    actions: [
        Kirigami.SettingAction {
            text: i18n("General")
            icon.name: "koko"
            page: "qrc:/qml/GeneralSettings.qml"
        },
        Kirigami.SettingAction {
            text: i18n("About")
            icon.name: "help-about"
            page: "qrc:/qml/AboutPage.qml"
        }
    ]
}
