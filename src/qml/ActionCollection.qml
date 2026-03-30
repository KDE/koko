/*
 * SPDX-FileCopyrightText: (C) 2026 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami.actioncollection as AC
import org.kde.koko as Koko

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
            name: "ToggleFavorite"
            icon.name: "non-starred-symbolic"
            text: i18nc("@action:intoolbar Favorite an image/video", "Favorite")
            checkable: true
        }
        AC.ActionData {
            name: "EditImage"
            icon.name: "edit-entry"
            text: i18nc("@action:intoolbar Edit an image", "Edit")
            toolTip: i18nc("@info:tooltip", "Edit this image")
            defaultShortcut: "Ctrl+E"
        }
        AC.ActionData {
            name: "Share"
            icon.name: "edit-entry"
            text: i18nc("@action:intoolbar Share an image/video", "Share")
            defaultShortcut: "Ctrl+S"
        }
        AC.ActionData {
            name: "Info"
            text: i18nc("@action:intoolbar Show information about an image/video", "Info")
            icon.name: "info-symbolic"
            defaultShortcut: "I"
            checkable: true
        }

        AC.StandardActionData {
            standardAction: AC.StandardActionData.SaveAs
        }
        AC.ActionData {
            name: "OpenFolder"
            text: i18nc("@action:inmenu", "Open Containing Folder")
            icon.name: "folder-open"
        }
        AC.ActionData {
            name: "OpenWith"
            text: i18nc("@action:inmenu", "&Open With…")
            icon.name: "system-run"
        }
        AC.StandardActionData {
            standardAction: AC.StandardActionData.Copy
        }
        AC.ActionData {
            name: "CopyPath"
            text: i18nc("@action:inmenu", "Copy Location")
            icon.name: "edit-copy-path"
        }
        AC.StandardActionData {
            standardAction: AC.StandardActionData.MoveToTrash
        }
        AC.StandardActionData {
            standardAction: AC.StandardActionData.DeleteFile
        }
        AC.StandardActionData {
            standardAction: AC.StandardActionData.Print
        }

        AC.ActionData {
            name: "Slideshow"
            text: i18nc("@action:intoolbar Start a slideshow", "Slideshow")
            icon.name: "view-presentation-symbolic"
            toolTip: i18nc("@info:tooltip", "Start slideshow")
        }
        AC.ActionData {
            name: "ShowControls"
            text: i18nc("@action:intoolbar Toggle visibility of toolbars and other UI elements", "Show Controls")
            checkable: true
        }
        AC.ActionData {
            name: "ShowThumbnailToolBar"
            text: i18nc("@action:intoolbar Toggle visibility of toolbar", "Show Thumbnail Toolbar")
            toolTip: !Koko.Config.imageViewPreview ? i18nc("@info:tooltip", "Show the thumbnail toolbar")
                                                   : i18nc("@info:tooltip", "Hide the thumbnail toolbar")
            defaultShortcut: "T"
            checkable: true
        }
        AC.ActionData {
            name: "Fullscreen"
            text: i18nc("@action:intoolbar", "Full Screen")
            icon.name: !checked ? "view-fullscreen-symbolic" : "view-restore-symbolic"
            toolTip: !checked ? i18nc("@info:tooltip", "Enter Full Screen") : i18nc("@info:tooltip", "Exit Full Screen")

            defaultShortcut: "F"
            checkable: true
        }
    }
}
