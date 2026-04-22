// SPDX-FileCopyrightText: 2025 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigami.delegates as KD
import org.kde.koko as Koko

Kirigami.ScrollablePage {
    id: root

    property Koko.Exiv2Extractor extractor

    title: i18nc("@title", "Configure Metadata Display")

    ListView {
        model: root.extractor
        delegate: KD.CheckSubtitleDelegate {
            id: delegate

            required property int index
            required property string label
            required property string key
            required property string displayName
            required property bool enabledRole

            width: ListView.view.width

            text: label
            subtitle: delegate.displayName.length > 0 ? delegate.displayName : i18nc("@label Placeholder for missing metadata", "—")

            checked: enabledRole
            highlighted: down

            onToggled: {
                if (checked) {
                    Koko.Config.metadataToDisplay.push(delegate.key)
                    Koko.Config.save();
                } else {
                    const indexOfKey = Koko.Config.metadataToDisplay.indexOf(delegate.key);
                    if (indexOfKey > 0) {
                        Koko.Config.metadataToDisplay.splice(indexOfKey, 1);
                        Koko.Config.save();
                    }
                }
            }

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
