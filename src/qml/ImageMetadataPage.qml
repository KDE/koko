// SPDX-FileCopyrightText: 2025 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko
import org.kde.kirigamiaddons.delegates as Delegates

Kirigami.ScrollablePage {
    id: root

    property Koko.Exiv2Extractor extractor

    title: i18nc("@title", "Metadata")

    ListView {
        currentIndex: -1
        model: extractor
        delegate: Delegates.RoundedItemDelegate {
            id: delegate

            required property int index
            required property string label
            required property string key
            required property string displayName
            required property bool enabledRole

            text: label
            checkable: true
            checked: enabledRole

            onToggled: update()

            function update(): void {
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

            Accessible.description: displayName

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Controls.CheckBox {
                    id: checkBox

                    onToggled: {
                        delegate.checked = checked
                        delegate.update()
                    }
                    checked: delegate.checked
                }

                Delegates.SubtitleContentItem {
                    subtitle: delegate.displayName
                    itemDelegate: delegate
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
