/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as QQC2
import org.kde.koko 0.1 as Koko

import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.delegates 1.0 as Delegates

Kirigami.OverlayDrawer {
    edge: Qt.application.layoutDirection == Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    handleVisible: !applicationWindow().fetchImageToOpen && modal && pageStack.layers.depth < 2

    // Autohiding behavior
    modal: applicationWindow().fetchImageToOpen || !root.wideScreen
    onEnabledChanged: drawerOpen = enabled && !modal
    onModalChanged: drawerOpen = !modal && pageStack.layers.depth < 2

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: Math.round(Kirigami.Units.smallSpacing / 2)

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

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
            implicitWidth: Kirigami.Units.gridUnit * 14

            Layout.fillHeight: true
            Layout.fillWidth: true

            Accessible.role: Accessible.MenuBar

            clip: true

            component PlaceHeading : Kirigami.ListSectionHeader {
                Layout.fillWidth: true
            }

            component PlaceItem : Delegates.RoundedItemDelegate {
                id: item
                property string filter
                property string query

                Layout.fillWidth: true
                Keys.onDownPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocusReason)
                Accessible.role: Accessible.MenuItem

                onClicked: {
                    scrollView.currentlySelectedAction = item;

                    if (scrollView.previouslySelectedAction) {
                        scrollView.previouslySelectedAction.checked = false;
                    }

                    scrollView.currentlySelectedAction.checked = true;

                    applicationWindow().filterBy(filter, query);

                    scrollView.previouslySelectedAction = item;
                }
            }

            ColumnLayout {
                spacing: 1
                width: scrollView.availableWidth
                PlaceHeading {
                    text: i18n("Places")
                }
                PlaceItem {
                    id: picturesAction
                    icon.name: "folder-pictures"
                    text: i18n("Pictures")
                    filter: "Pictures"
                }
                PlaceItem {
                    text: i18n("Favorites")
                    icon.name: "starred-symbolic"
                    filter: "Favorites"
                }
                PlaceItem {
                    icon.name: "folder-videos"
                    text: i18n("Videos")
                    filter: "Videos"
                    query: "file://" + Koko.DirModelUtils.videos
                }
                Repeater {
                    model: kokoConfig.savedFolders
                    PlaceItem {
                        icon.name: "folder-symbolic"
                        text: {
                            var str = modelData
                            if (str.endsWith("/")) {
                                str = str.slice(0, -1)
                            }
                            return str.split("/")[str.split("/").length-1]
                        }
                        filter: "Folders"
                        query: modelData
                    }
                }
                PlaceItem {
                    icon.name: "user-trash-symbolic"
                    text: i18n("Trash")
                    filter: "Trash"
                    query: "trash:/"
                }
                PlaceHeading {
                    text: i18nc("Remote network locations", "Remote")
                }
                PlaceItem {
                    icon.name: "folder-cloud"
                    text: i18n("Network")
                    filter: "Remote"
                    query: "remote:/"
                }
                PlaceHeading {
                    text: i18n("Locations")
                }
                PlaceItem {
                    text: i18n("Countries")
                    icon.name: "tag-places"
                    filter: "Countries"
                }
                PlaceItem {
                    text: i18n("States")
                    icon.name: "tag-places"
                    filter: "States"
                }
                PlaceItem {
                    text: i18n("Cities")
                    icon.name: "tag-places"
                    filter: "Cities"
                }
                PlaceHeading {
                    text: i18n("Time")
                }
                PlaceItem {
                    text: i18n("Years")
                    icon.name: "view-calendar"
                    filter: "Years"
                }
                PlaceItem {
                    text: i18n("Months")
                    icon.name: "view-calendar"
                    filter: "Months"
                }
                PlaceItem {
                    text: i18n("Weeks")
                    icon.name: "view-calendar"
                    filter: "Weeks"
                }
                PlaceItem {
                    text: i18n("Days")
                    icon.name: "view-calendar"
                    filter: "Days"
                }
                PlaceHeading {
                    text: i18n("Tags")
                    visible: applicationWindow().tags.length > 0
                }
                Repeater {
                    model: applicationWindow().tags
                    PlaceItem {
                        icon.name: "tag"
                        text: modelData
                        filter: "Tags"
                        query: modelData
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
            QQC2.ToolTip.text: i18n("%1 px", kokoConfig.iconSize)
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            from: Kirigami.Units.gridUnit * 4
            to: Kirigami.Units.gridUnit * 8
            value: kokoConfig.iconSize
            onMoved: kokoConfig.iconSize = value;
        }

        Delegates.RoundedItemDelegate {
            text: i18n("Settings")
            onClicked: applicationWindow().openSettingsPage()
            icon.name: "settings-configure"
            Layout.fillWidth: true
        }
    }


    Component.onCompleted: {
        picturesAction.checked = true;
        scrollView.currentlySelectedAction = picturesAction;
        scrollView.previouslySelectedAction = picturesAction;
    }
}
