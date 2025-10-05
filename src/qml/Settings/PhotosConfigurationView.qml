// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick

import org.kde.koko as Koko
import org.kde.kirigamiaddons.settings as KirigamiSettings

KirigamiSettings.ConfigurationView {
    id: root

    required property Koko.PhotosApplication application

    modules: [
        KirigamiSettings.ConfigurationModule {
            moduleId: "general"
            text: i18nc("@action:button", "General")
            icon.name: "preferences-desktop-theme-global"
            page: () => Qt.createComponent("org.kde.koko", "GeneralConfigPage")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "ocr"
            text: i18nc("@action:button", "Text extraction")
            icon.name: "insert-text"
            page: () => Qt.createComponent("org.kde.koko", "OcrConfigPage")
        },
        KirigamiSettings.ShortcutsConfigurationModule {
            application: root.application
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "about"
            text: i18n("About Photos")
            icon.name: "org.kde.koko"
            page: () => Qt.createComponent("org.kde.kirigamiaddons.formcard", "AboutPage")
            category: i18nc("@title:group", "About")
        },
        KirigamiSettings.ConfigurationModule {
            moduleId: "aboutkde"
            text: i18n("About KDE")
            icon.name: "kde"
            page: () => Qt.createComponent("org.kde.kirigamiaddons.formcard", "AboutKDEPage")
            category: i18nc("@title:group", "About")
        }
    ]
}
