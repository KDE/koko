/*
 * SPDX-FileCopyrightText: Copyright 2021 Devin Lin <espidev@gmail.com>
 * SPDX-FileCopyrightText: Copyright 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.statefulapp as StatefulApp
import org.kde.koko as Koko

Loader {
    id: root

    enum Category {
        Pictures,
        Videos,
        Favorites,
        Places
    }

    property int lastCategoryRequested: BottomNavBar.Category.Pictures // tracks last page selected

    required property StatefulApp.StatefulWindow mainWindow

    height: active ? implicitHeight : 0
    active: Kirigami.Settings.isMobile && !mainWindow.wideScreen && mainWindow.pageStack.layers.depth < 2;
    sourceComponent: bottomNavBar

    Connections {
        target: mainWindow

        function onPlacesOpened(): void {
            root.lastCategoryRequested = BottomNavBar.Category.Places
        }
    }

    Component {
        id: bottomNavBar

        Kirigami.NavigationTabBar {
            position: Kirigami.NavigationTabBar.Footer
            actions: [
                Kirigami.Action {
                    id: picturesAction

                    text: i18nc("@action:button Navigation entry in sidebar", "Pictures")
                    fromQAction: root.mainWindow.application.action("place_pictures")
                },
                Kirigami.Action {
                    id: videosAction

                    text: i18nc("@action:button Navigation entry in sidebar", "Videos")
                    fromQAction: root.mainWindow.application.action("place_videos")
                },
                Kirigami.Action {
                    id: favoritesAction

                    text: i18nc("@action:button Navigation entry in sidebar", "Favorites")
                    fromQAction: root.mainWindow.application.action("place_favorites")
                },
                Kirigami.Action {
                    icon.name: "compass-symbolic"
                    text: i18n("Places")
                    checked: !picturesAction.checked && !videosAction.checked && !favoritesAction.checked
                    onTriggered: root.mainWindow.openPlacesPage();
                }
            ]
        }
    }
}
