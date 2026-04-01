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
import org.kde.kirigami.actioncollection as AC
import org.kde.kirigamiaddons.delegates as Delegates
import org.kde.kirigamiaddons.statefulapp as StatefulApp

import org.kde.coreaddons as CoreAddons

import org.kde.koko as Koko

Kirigami.OverlayDrawer {
    id: root

    required property Kirigami.ApplicationWindow mainWindow
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
                            AC.ActionCollection.action: "Preferences"
                            AC.ActionCollection.collection: "org.kde.globalactions"
                            onTriggered: root.configurationView.open()
                        }

                        Kirigami.Action {
                            AC.ActionCollection.action: "KeyBindings"
                            AC.ActionCollection.collection: "org.kde.globalactions"
                        }

                        Kirigami.Action {
                            AC.ActionCollection.action: "FindAction"
                            AC.ActionCollection.collection: "org.kde.globalactions"
                        }

                        QQC2.MenuSeparator {}

                        Kirigami.Action {
                            AC.ActionCollection.action: "AboutApp"
                            AC.ActionCollection.collection: "org.kde.globalactions"
                        }

                        Kirigami.Action {
                            AC.ActionCollection.action: "AboutKDE"
                            AC.ActionCollection.collection: "org.kde.globalactions"
                        }

                        Kirigami.Action {
                            AC.ActionCollection.action: "Donate"
                            AC.ActionCollection.collection: "org.kde.globalactions"
                        }

                        Kirigami.Action {
                            AC.ActionCollection.action: "ReportBug"
                            AC.ActionCollection.collection: "org.kde.globalactions"
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
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_pictures"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Videos")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_videos"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Favorites")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_favorites"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    icon.name: "user-trash-symbolic"
                    text: i18nc("@action:button Navigation entry in sidebar", "Trash")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_trash"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
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
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_remote"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceHeading {
                    text: i18n("Locations")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Countries")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_countries"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "States")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_states"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Cities")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_cities"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceHeading {
                    text: i18n("Time")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Years")
                    action: Kirigami.Action {
                        AC.ActionCollection.action: "place_years"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Months")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_months"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Weeks")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_weeks"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Days")
                    placeAction: Kirigami.Action {
                        AC.ActionCollection.action: "place_days"
                        AC.ActionCollection.collection: "org.kde.koko.navigation"
                    }
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
