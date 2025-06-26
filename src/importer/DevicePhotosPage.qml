// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

import org.kde.koko as Koko

Kirigami.ScrollablePage {
    id: root

    GridView {
        id: gridView

        cellWidth: Math.floor(width/Math.floor(width/(Koko.Config.iconSize + Kirigami.Units.largeSpacing * 2)))
        cellHeight: Koko.Config.iconSize + Kirigami.Units.largeSpacing * 2

        model: Koko.SortModel {
            filterRole: Koko.Roles.MimeTypeRole
            sourceModel: Koko.ImageFolderModel {
                url: "camera:/"
            }
        }

        delegate: Koko.AlbumDelegate {
            id: delegate

            highlighted: gridView.currentIndex == index

            Controls.ToolTip.text: Koko.DirModelUtils.fileNameOfUrl(model.imageurl)
            Controls.ToolTip.visible: hovered && model.itemType === Koko.Types.Image
            Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
