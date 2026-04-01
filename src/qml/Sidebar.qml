/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.statefulapp as StatefulApp

import org.kde.coreaddons as CoreAddons

import org.kde.koko as Koko

Kirigami.OverlayDrawer {
    id: root

    required property StatefulApp.StatefulWindow mainWindow
    required property Koko.PhotosApplication application
    required property int sidebarWidth
    readonly property var galleryModel: mainWindow.galleryPage?.galleryModel ?? null

    edge: Application.layoutDirection == Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    handleVisible: modal && mainWindow.pageStack.layers.depth < 2

    // Autohiding behavior
    modal: !mainWindow.wideScreen
    onModalChanged: drawerOpen = !modal && mainWindow.pageStack.layers.depth < 2

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    // This makes the sidebar header separator look like a discrete item
    readonly property alias header: sidebarHeader

    // Place
    contentItem: ColumnLayout {
        id: column

        spacing: 0

        Kirigami.AbstractApplicationHeader {
            id: sidebarHeader
            Layout.fillWidth: true

            RowLayout {
                anchors.fill: parent

                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    // Align with sidebar ListSectionHeader margins, which is smallSpacing + mediumSpacing
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    text: i18n("Places")
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                QQC2.ToolButton {
                    id: menuButton

                    icon.name: "application-menu"

                    QQC2.ToolTip.text: i18nc("@info:tooltip", "Show menu")
                    QQC2.ToolTip.visible: hovered && !mainMenu.visible
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                    onPressed: mainMenu.open()
                    down: pressed || mainMenu.visible

                    QQC2.Menu {
                        id: mainMenu
                        y: menuButton.height

                        Kirigami.Action {
                            fromQAction: root.application.action('options_configure')
                        }

                        QQC2.MenuSeparator {}

                        Kirigami.Action {
                            fromQAction: root.application.action('open_about_page')
                        }

                        Kirigami.Action {
                            icon.name: "kde-symbolic"
                            fromQAction: root.application.action('open_about_kde_page')
                        }

                        Kirigami.Action {
                            text: i18nc("@action:inMenu", "Donate…")
                            icon.name: "help-donate-" + Qt.locale().currencySymbol(Locale.CurrencyIsoCode).toLowerCase() + "-symbolic"
                            onTriggered: Qt.openUrlExternally("https://kde.org/donate/?app=koko")
                        }

                        Kirigami.Action {
                            text: i18nc("@action:inMenu", "Report Bug…")
                            icon.name: "tools-report-bug-symbolic"
                            onTriggered: Qt.openUrlExternally("https://bugs.kde.org/enter_bug.cgi?format=guided&product=koko&version=" + CoreAddons.AboutData.version)
                        }
                    }
                }
            }
        }

        QQC2.ScrollView {
            id: scrollView
            property var currentlySelectedAction
            property var previouslySelectedAction

            contentWidth: -1
            implicitWidth: root.sidebarWidth

            Layout.fillHeight: true
            Layout.fillWidth: true

            Accessible.role: Accessible.MenuBar

            clip: true

            component PlaceHeading : Kirigami.ListSectionHeader {
                Layout.fillWidth: true
            }

            component PlaceItem : Delegates.RoundedItemDelegate {
                id: item
                required property var placeAction
                readonly property bool shouldBeChecked: {
                    const pathsEqual = (JSON.stringify(placeAction.path) === JSON.stringify(root.galleryModel.path));
                    if (!pathsEqual && placeAction.modelType !== Koko.PhotosApplication.FavoritesModel) {
                        // GalleryFavoritesModel is excluded because it is not navigable, and has no path
                        return false;
                    }

                    switch (placeAction.modelType) {
                        case Koko.PhotosApplication.FolderModel:
                            return root.galleryModel instanceof Koko.GalleryFolderModel;
                        case Koko.PhotosApplication.FavoritesModel:
                            return root.galleryModel instanceof Koko.GalleryFavoritesModel;
                        case Koko.PhotosApplication.LocationModel:
                            return root.galleryModel instanceof Koko.GalleryLocationModel;
                        case Koko.PhotosApplication.TimeModel:
                            return root.galleryModel instanceof Koko.GalleryTimeModel;
                        case Koko.PhotosApplication.TagsModel:
                            return root.galleryModel instanceof Koko.GalleryTagsModel;
                        default:
                            return false;
                    }
                }
                // Get most of the Kirigami Action and button states from the QAction, but not all
                action: Kirigami.Action {
                    fromQAction: item.placeAction
                    checked: item.shouldBeChecked
                }
                // automatically unchecks when another is checked,
                // but don't assume that its impossible to uncheck all
                autoExclusive: true
                Layout.fillWidth: true
                Keys.onDownPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocusReason)
                Accessible.role: Accessible.MenuItem
                // When these actions are checked elsewhere, it needs to be communicated here
                // Connections {
                //     target: item.placeAction
                //     function onToggled(checked: bool) : void {
                //         item.checked = checked ? checked : Qt.binding(() => item.shouldBeChecked)
                //     }
                // }
            }

            ColumnLayout {
                spacing: 1
                width: scrollView.availableWidth
                PlaceHeading {
                    text: i18n("General")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Pictures")
                    placeAction: root.application.action('place_pictures')
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Videos")
                    placeAction: root.application.action('place_videos')
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Favorites")
                    placeAction: root.application.action('place_favorites')
                }
                PlaceItem {
                    icon.name: "user-trash-symbolic"
                    text: i18nc("@action:button Navigation entry in sidebar", "Trash")
                    placeAction: root.application.action('place_trash')
                }
                PlaceHeading {
                    visible: savedFoldersRepeater.count > 0
                    text: i18nc("@title:group", "Bookmarks")
                }
                Repeater {
                    id: savedFoldersRepeater
                    model: root.application.savedFolders
                    PlaceItem {
                        id: delegate

                        required property var modelData

                        placeAction: delegate.modelData
                    }
                }
                PlaceHeading {
                    text: i18nc("Remote network locations", "Remote")
                }
                PlaceItem {
                    icon.name: "folder-cloud"
                    text: i18nc("@action:button Navigation entry in sidebar", "Network")
                    placeAction: root.application.action('place_remote')
                }
                PlaceHeading {
                    text: i18n("Locations")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Countries")
                    placeAction: root.application.action('place_countries')
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "States")
                    placeAction: root.application.action('place_states')
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Cities")
                    placeAction: root.application.action('place_cities')
                }
                PlaceHeading {
                    text: i18n("Time")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Years")
                    placeAction: root.application.action('place_years')
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Months")
                    placeAction: root.application.action('place_months')
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Weeks")
                    placeAction: root.application.action('place_weeks')
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Days")
                    placeAction: root.application.action('place_days')
                }
                PlaceHeading {
                    text: i18n("Tags")
                    visible: tagRepeater.count > 0
                }
                Repeater {
                    id: tagRepeater
                    model: root.application.tags
                    PlaceItem {
                        id: placeItem

                        required property var modelData

                        placeAction: placeItem.modelData
                    }
                }
            }
        }
    }
}
