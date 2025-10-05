// SPDX-FileCopyrightText: 2025 Florian RICHER <florian.richer@protonmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.koko as Koko

FormCard.FormCardPage {
    Layout.topMargin: Kirigami.Units.largeSpacing * 2

    FormCard.FormHeader {
        title: i18nc("@title:group", "Select the languages")
    }

    FormCard.FormCard {
        Repeater {
            model: Koko.Ocr.availableLanguages

            delegate: FormCard.FormCheckDelegate {
                text: modelData
                checked: Koko.Ocr.loadedLanguages.indexOf(modelData) > -1
                onToggled: {
                    if (checkState) {
                        Koko.Ocr.loadLanguage(modelData)
                    } else {
                        Koko.Ocr.unloadLanguage(modelData)
                    }
                }
            }
        }
    }
}
