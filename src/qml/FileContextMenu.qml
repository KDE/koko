// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.12 as Kirigami

Menu {
    required property url: fileUrl
    Component {
        Kirigami.OverlaySheet {
            id: createFolderSheet
            title: i18n("New Folder")
            ColumnLayout {
                Label {
                    text: i18n("Create new folder in %1:", folderUrl)
                }
                TextField {
                    text: i18nc("Default name for the new folder", "New Folder")
                }
            }
        }
    }
    MenuItem {
        text: i18n("Create Folder")
    }
    MenuSeparator { }
    MenuItem {
        text: i18n("Rename")
    }
    MenuItem {
        text: i18n("Trash")
    }
    MenuItem {
        text: i18n("Delete")
    }
    MenuSeparator { }
    MenuItem {
        text: i18n("Copy To...")
    }
    MenuItem {
        text: i18n("Move To...")
    }
    MenuItem {
        text: i18n("Link To...")
    }
    MenuSeparator { }
    MenuItem {
        text: i18n("Open With")
    }
}
