// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick

import org.kde.koko as Koko
import org.kde.kirigami as Kirigami
import org.kde.kirigami.settings as KirigamiSettings

KirigamiSettings.SettingsViewController {
    id: root

    modules: [
        KirigamiSettings.SettingsModule {
            moduleId: "general"
            name: i18nc("@action:button", "General")
            icon.name: "photo-symbolic"
            page: Koko.GeneralConfigPage {}
        },
        KirigamiSettings.ShortcutsSettingsModule {
            allowModifierlessShortcuts: true
        },
        KirigamiSettings.SettingsModule {
            moduleId: "about"
            name: i18n("About Photos")
            icon.name: "help-about-symbolic"
            page: () => Qt.createComponent("org.kde.kirigamiaddons.formcard", "AboutPage")
            category: i18nc("@title:group", "About")
            visible: Kirigami.Settings.isMobile
        },
        KirigamiSettings.SettingsModule {
            moduleId: "aboutkde"
            name: i18n("About KDE")
            icon.name: "kde-symbolic"
            page: () => Qt.createComponent("org.kde.kirigamiaddons.formcard", "AboutKDEPage")
            category: i18nc("@title:group", "About")
            visible: Kirigami.Settings.isMobile
        }
    ]
}
