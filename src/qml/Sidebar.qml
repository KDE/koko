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

    required property StatefulApp.StatefulWindow mainWindow
    required property Koko.PhotosApplication application
    required property int sidebarWidth

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
                            objectName: "Preferences"
                            AC.ActionCollection.collection: "org.kde.standardactions"
                            onTriggered: root.application.configurationView.open()
                        }

                        Kirigami.Action {
                            objectName: "KeyBindings"
                            AC.ActionCollection.collection: "org.kde.standardactions"
                        }

                        Kirigami.Action {
                            objectName: "FindAction"
                            AC.ActionCollection.collection: "org.kde.standardactions"
                        }

                        QQC2.MenuSeparator {}

                        Kirigami.Action {
                            objectName: "AboutApp"
                            AC.ActionCollection.collection: "org.kde.standardactions"
                        }

                        Kirigami.Action {
                            objectName: "AboutKDE"
                            AC.ActionCollection.collection: "org.kde.standardactions"
                        }

                        Kirigami.Action {
                            objectName: "Donate"
                            AC.ActionCollection.collection: "org.kde.standardactions"
                        }

                        Kirigami.Action {
                            objectName: "ReportBug"
                            AC.ActionCollection.collection: "org.kde.standardactions"
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

                Layout.fillWidth: true
                Keys.onDownPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocusReason)
                Accessible.role: Accessible.MenuItem
            }

            ColumnLayout {
                spacing: 1
                width: scrollView.availableWidth
                PlaceHeading {
                    text: i18n("General")
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
                    text: i18nc("@title:group", "Bookmarks")
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
                        id: placeItem

                        required property var modelData

                        action: Kirigami.Action {
                            fromQAction: placeItem.modelData
                        }
                    }
                }
            }
        }
    }
}
