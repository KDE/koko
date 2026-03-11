/*
 * SPDX-FileCopyrightText: (C) 2026 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami.actioncollection as AC

AC.ActionCollectionManager {
    id: manager
    pageRow: root.pageStack

    AC.ActionCollection {
        name: "org.kde.koko.gallery"
        text: i18nc("Actions category", "Gallery")
        AC.ActionData {
            name: "SelectAll"
            icon.name: "edit-select-all-symbolic"
            text: i18nc("@action:button", "Select All")
            toolTip: i18nc("@info:tooltip", "Select all media")
            defaultShortcut: StandardKey.SelectAll
        }
        AC.ActionData {
            name: "SelectNone"
            icon.name: "edit-select-none-symbolic"
            text: i18nc("@action:button", "Select None")
            toolTip: i18nc("@info:tooltip", "Deselect all media")
            defaultShortcut: StandardKey.Deselect
        }
        AC.ActionData {
            name: "InvertSelection"
            icon.name: "edit-select-invert-symbolic"
            text: i18nc("@action:button", "Invert Selection")
            toolTip: i18nc("@info:tooltip", "Invert the selected media")
        }
    }

    AC.ActionCollection {
        name: "org.kde.koko.mediaview"
        text: i18nc("Actions category", "Media View")
        AC.ActionData {
            name: "EditImage"
            icon.name: "edit-entry"
            text: i18nc("@action:intoolbar Edit an image", "&Edit")
            toolTip: i18nc("@info:tooltip", "Edit this image")
            defaultShortcut: "Ctrl+E"
        }
    }
}
