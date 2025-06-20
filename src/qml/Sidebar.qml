/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.koko as Koko

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates

Kirigami.OverlayDrawer {
    id: root

    required property QQC2.ApplicationWindow mainWindow
    required property Koko.PhotosApplication application
    required property int sidebarWidth

    edge: Qt.application.layoutDirection == Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    handleVisible: !mainWindow.fetchImageToOpen && modal && pageStack.layers.depth < 2

    // Autohiding behavior
    modal: mainWindow.fetchImageToOpen || !mainWindow.wideScreen
    onEnabledChanged: drawerOpen = enabled && !modal
    onModalChanged: drawerOpen = !modal && pageStack.layers.depth < 2

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: Math.round(Kirigami.Units.smallSpacing / 2)

    // Place
    contentItem: ColumnLayout {
        id: column
        // FIXME: Dirty workaround for 385992
        spacing: 0
        Kirigami.AbstractApplicationHeader {
            topPadding: Kirigami.Units.smallSpacing;
            bottomPadding: Kirigami.Units.smallSpacing;
            leftPadding: Kirigami.Units.largeSpacing
            rightPadding: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
            Kirigami.Heading {
                level: 1
                text: i18n("Filter by")
            }
        }
        QQC2.ScrollView {
            id: scrollView
            property var currentlySelectedAction
            property var previouslySelectedAction

            contentWidth: -1
            implicitWidth: root.sidebarWidth
            bottomPadding: Math.round(Kirigami.Units.smallSpacing / 2)

            Layout.fillHeight: true
            Layout.fillWidth: true

            Accessible.role: Accessible.MenuBar

            clip: true

            component PlaceHeading : Kirigami.ListSectionHeader {
                Layout.fillWidth: true
            }

            component PlaceItem : Delegates.RoundedItemDelegate {
                id: item

                Layout.fillWidth: true
                Keys.onDownPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocusReason)
                Accessible.role: Accessible.MenuItem
            }

            ColumnLayout {
                spacing: 1
                width: scrollView.availableWidth
                PlaceHeading {
                    text: i18n("Places")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Pictures")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_pictures')
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Videos")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_videos')
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Favorites")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_favorites')
                    }
                }
                PlaceItem {
                    icon.name: "user-trash-symbolic"
                    text: i18nc("@action:button Navigation entry in sidebar", "Trash")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_trash')
                    }
                }
                PlaceHeading {
                    visible: savedFoldersRepeater.count > 0
                    text: i18nc("@title:group", "Pinned Folders")
                }
                Repeater {
                    id: savedFoldersRepeater
                    model: root.application.savedFolders
                    PlaceItem {
                        id: delegate

                        required property var modelData

                        action: Kirigami.Action {
                            fromQAction: delegate.modelData
                        }
                    }
                }
                PlaceHeading {
                    text: i18nc("Remote network locations", "Remote")
                }
                PlaceItem {
                    icon.name: "folder-cloud"
                    text: i18nc("@action:button Navigation entry in sidebar", "Network")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_remote')
                    }
                }
                PlaceHeading {
                    text: i18n("Locations")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Countries")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_countries')
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "States")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_states')
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Cities")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_cities')
                    }
                }
                PlaceHeading {
                    text: i18n("Time")
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Years")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_years')
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Months")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_months')
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Weeks")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_weeks')
                    }
                }
                PlaceItem {
                    text: i18nc("@action:button Navigation entry in sidebar", "Days")
                    action: Kirigami.Action {
                        fromQAction: root.application.action('place_days')
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
                        required property var modelData
                        action: Kirigami.Action {
                            fromQAction: modelData
                        }
                    }
                }
            }
        }
        QQC2.ToolSeparator {
            Layout.topMargin: -1;
            Layout.fillWidth: true
            orientation: Qt.Horizontal
            visible: scrollView.contentHeight > scrollView.height
        }

        PlaceHeading {
            Layout.topMargin: -Kirigami.Units.smallSpacing;
            text: i18n("Thumbnails size:")
        }

        QQC2.Slider {
            QQC2.ToolTip.text: i18n("%1 px", Koko.Config.iconSize)
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            from: Kirigami.Units.gridUnit * 4
            to: Kirigami.Units.gridUnit * 8
            value: Koko.Config.iconSize
            onMoved: {
                Koko.Config.iconSize = value;
                Koko.Config.save();
            }
        }

        Delegates.RoundedItemDelegate {
            text: i18n("Settings")
            action: Kirigami.Action {
                text: i18nc("@action:button Open settings dialog", "Settings")
                fromQAction: root.application.action('options_configure')
            }

            Layout.fillWidth: true
        }
    }
}
