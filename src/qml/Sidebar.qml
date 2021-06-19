/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as QQC2
import org.kde.koko 0.1 as Koko

import org.kde.kirigami 2.5 as Kirigami

Kirigami.OverlayDrawer {
    signal filterBy(string value, string query)
    property var currentlySelectedAction
    property var previouslySelectedAction
    property var tags
    property alias contentObject: column.children

    edge: Qt.application.layoutDirection == Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    handleClosedIcon.source: null
    handleOpenIcon.source: null
    handleVisible: (modal || !drawerOpen) && (typeof(applicationWindow)===typeof(Function) && applicationWindow() ? applicationWindow().controlsVisible : true)

    // Autohiding behavior
    modal: !root.wideScreen
    onEnabledChanged: drawerOpen = enabled && !modal
    onModalChanged: drawerOpen = !modal && pageStack.layers.depth < 2

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    // Place
    contentItem: ColumnLayout {
        id: column
        // FIXME: Dirty workaround for 385992
        implicitWidth: Kirigami.Units.gridUnit * 14
        Kirigami.AbstractApplicationHeader {
            topPadding: Kirigami.Units.smallSpacing;
            bottomPadding: Kirigami.Units.smallSpacing;
            leftPadding: Kirigami.Units.largeSpacing
            rightPadding: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
            Kirigami.Heading {
                level: 1
                text: i18n("Sort by")
            }
        }
        QQC2.ScrollView {
            id: scrollView
            Layout.topMargin: -Kirigami.Units.smallSpacing - 1;
            Layout.bottomMargin: -Kirigami.Units.smallSpacing;
            Layout.fillHeight: true
            Layout.fillWidth: true

            Accessible.role: Accessible.MenuBar
            contentWidth: availableWidth

            clip: true

            component PlaceHeading : Kirigami.Heading {
                topPadding: Kirigami.Units.largeSpacing
                leftPadding: Kirigami.Units.largeSpacing
                Layout.fillWidth: true
                level: 6
                opacity: 0.7
            }

            component PlaceItem : Kirigami.AbstractListItem {
                id: item
                property string icon
                property string filter
                property string query
                checkable: true
                separatorVisible: false
                Layout.fillWidth: true
                Keys.onDownPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocusReason)
                Accessible.role: Accessible.MenuItem
                leftPadding: Kirigami.Units.largeSpacing
                contentItem: Row {
                    Kirigami.Icon {
                        source: item.icon
                        width: height
                        height: Kirigami.Units.iconSizes.small
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    QQC2.Label {
                        leftPadding: Kirigami.Units.smallSpacing
                        text: item.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                onClicked: {
                    currentlySelectedAction = item
                    filterBy(filter, query)
                    previouslySelectedAction = item
                }
            }

            ColumnLayout {
                spacing: 1
                width: scrollView.width
                PlaceHeading {
                    text: i18n("Places")
                }
                PlaceItem {
                    id: picturesAction
                    icon: "folder-pictures"
                    text: i18n("Pictures")
                    filter: "Folders"
                }
                PlaceItem {
                    text: i18n("Favorites")
                    icon: "starred-symbolic"
                    filter: "Favorites"
                }
                PlaceItem {
                    icon: "folder-videos"
                    text: i18n("Videos")
                    filter: "Folders"
                    query: "file://" + Koko.DirModelUtils.videos
                }
                Repeater {
                    model: kokoConfig.savedFolders
                    PlaceItem {
                        icon: "folder-symbolic"
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
                    icon: "user-trash-symbolic"
                    text: i18n("Trash")
                    filter: "Trash"
                    query: "trash:/"
                }
                PlaceHeading {
                    text: i18nc("Remote network locations", "Remote")
                }
                PlaceItem {
                    icon: "folder-cloud"
                    text: i18n("Network")
                    filter: "Remote"
                    query: "remote:/"
                }
                PlaceHeading {
                    text: i18n("Locations")
                }
                PlaceItem {
                    text: i18n("Countries")
                    icon: "tag-places"
                    filter: "Countries"
                }
                PlaceItem {
                    text: i18n("States")
                    icon: "tag-places"
                    filter: "States"
                }
                PlaceItem {
                    text: i18n("Cities")
                    icon: "tag-places"
                    filter: "Cities"
                }
                PlaceHeading {
                    text: i18n("Time")
                }
                PlaceItem {
                    text: i18n("Years")
                    icon: "view-calendar"
                    filter: "Years"
                }
                PlaceItem {
                    text: i18n("Months")
                    icon: "view-calendar"
                    filter: "Months"
                }
                PlaceItem {
                    text: i18n("Weeks")
                    icon: "view-calendar"
                    filter: "Weeks"
                }
                PlaceItem {
                    text: i18n("Days")
                    icon: "view-calendar"
                    filter: "Days"
                }
                PlaceHeading {
                    text: i18n("Tags")
                    visible: tags.length > 0
                }
                Repeater {
                    model: tags
                    PlaceItem {
                        icon: "tag"
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
            QQC2.ToolTip.delay: Kirigami.Units.longDuration
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            from: Kirigami.Units.gridUnit * 4
            to: Kirigami.Units.gridUnit * 8
            value: kokoConfig.iconSize
            onMoved: kokoConfig.iconSize = value;
        }
    }


    Component.onCompleted: {
        picturesAction.checked = true
        currentlySelectedAction = picturesAction
        previouslySelectedAction = picturesAction
    }
}
