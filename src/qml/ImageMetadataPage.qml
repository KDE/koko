// SPDX-FileCopyrightText: 2025 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.kirigamiaddons.delegates as Delegates

Kirigami.ScrollablePage {
    id: root

    property Koko.Exiv2Extractor extractor

    title: i18nc("@title", "Metadata")

    ListView {
        model: extractor
        delegate: Delegates.RoundedItemDelegate {
            required property int index

            required property string label
            required property string displayName

            background: null
            text: label + ': ' + displayName
        }

        section {
            property: 'group'

            delegate: Kirigami.ListSectionHeader {
                required property string section
                text: section
                width: ListView.view.width
            }
        }
    }
}
