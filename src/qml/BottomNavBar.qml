/*
 * SPDX-FileCopyrightText: Copyright 2021 Devin Lin <espidev@gmail.com>
 * SPDX-FileCopyrightText: Copyright 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.koko 0.1 as Koko

Loader {
    id: root

    enum Category {
        Pictures,
        Videos,
        Favorites,
        Places
    }

    property int lastCategoryRequested: BottomNavBar.Category.Pictures // tracks last page selected

    height: active ? implicitHeight : 0
    active: Kirigami.Settings.isMobile && QQC2.ApplicationWindow.window.width <= applicationWindow().wideScreenWidth && applicationWindow().pageStack.layers.depth < 2;
    sourceComponent: bottomNavBar

    Connections {
        target: applicationWindow()
        function onFilterChanged(value, query) {
            switch (value) {
                case "Pictures": {
                    root.lastCategoryRequested = BottomNavBar.Category.Pictures
                    break;
                }
                case "Videos": {
                    root.lastCategoryRequested = BottomNavBar.Category.Videos
                    break;
                }
                case "Favorites": {
                    root.lastCategoryRequested = BottomNavBar.Category.Favorites
                    break;
                }
                default: {
                    root.lastCategoryRequested = BottomNavBar.Category.Places
                }
            }
        }
        function onPlacesOpened() {
            root.lastCategoryRequested = BottomNavBar.Category.Places
        }
    }

    Component {
        id: bottomNavBar
        ColumnLayout {
            spacing: 0
            Kirigami.NavigationTabBar {
                Layout.fillWidth: true
                position: Kirigami.NavigationTabBar.Footer
                actions: [
                    Kirigami.Action {
                        icon.name: "photo"
                        text: i18n("Pictures")
                        checked: root.lastCategoryRequested === BottomNavBar.Category.Pictures
                        onTriggered: applicationWindow().filterBy("Pictures", "")
                    },
                    Kirigami.Action {
                        icon.name: "folder-videos-symbolic"
                        text: i18n("Videos")
                        checked: root.lastCategoryRequested === BottomNavBar.Category.Videos
                        onTriggered: applicationWindow().filterBy("Videos", "file://" + Koko.DirModelUtils.videos)
                    },
                    Kirigami.Action {
                        icon.name: "emblem-favorite"
                        text: i18n("Favorites")
                        checked: root.lastCategoryRequested === BottomNavBar.Category.Favorites
                        onTriggered: applicationWindow().filterBy("Favorites", "");
                    },
                    Kirigami.Action {
                        icon.name: "compass"
                        text: i18n("Places")
                        checked: root.lastCategoryRequested === BottomNavBar.Category.Places
                        onTriggered: applicationWindow().openPlacesPage();
                    }
                ]
            }
        }
    }
}
