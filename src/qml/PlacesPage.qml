/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.15 as Kirigami

Kirigami.ScrollablePage {
    id: page

    leftPadding: 0
    rightPadding: 0

    actions: [
        Kirigami.Action {
            visible: Kirigami.Settings.isMobile && root.width <= applicationWindow().wideScreenWidth
            icon.name: "configure"
            text: i18n("Configure…")
            onTriggered: applicationWindow().openSettingsPage();
        }
    ]

    component PlaceHeading : Kirigami.Heading {
        topPadding: Kirigami.Units.largeSpacing
        leftPadding: Kirigami.Units.gridUnit
        Layout.fillWidth: true
        level: 1
    }

    component PlaceItem : QQC2.ItemDelegate {
        id: item
        property string filter
        property string query
        Layout.fillWidth: true
        Accessible.role: Accessible.MenuItem
        height: implicitHeight
        contentItem: Column {
            Kirigami.Icon {
                source: item.icon.name
                width: height
                height: Kirigami.Units.iconSizes.huge
                anchors.horizontalCenter: parent.horizontalCenter
            }
            QQC2.Label {
                text: item.text
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        onClicked: {
            applicationWindow().filterBy(filter, query);
        }
    }

    component PlaceItemContainer : QQC2.ScrollView {
        default property alias rowChildren: row.data
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
        Layout.fillWidth: true
        leftPadding: Kirigami.Units.gridUnit

        Row {
            id: row
        }
        DragHandler {
            yAxis.enabled: false
        }
    }

    ColumnLayout {
        PlaceItemContainer {
            PlaceItem {
                icon.name: "folder-cloud"
                text: i18n("Network")
                filter: "Remote"
                query: "remote:/"
            }
            PlaceItem {
                icon.name: "user-trash"
                text: i18n("Trash")
                filter: "Trash"
                query: "trash:/"
            }
        }
        PlaceHeading {
            text: i18n("Pinned Folders")
        }
        PlaceItemContainer {
            Repeater {
                model: kokoConfig.savedFolders
                PlaceItem {
                    icon.name: "folder"
                    text: {
                        var str = modelData;
                        if (str.endsWith("/")) {
                            str = str.slice(0, -1);
                        }
                        return str.split("/")[str.split("/").length-1];
                    }
                    filter: "Folders"
                    query: modelData
                }
            }
        }
        PlaceHeading {
            text: i18n("Locations")
        }
        PlaceItemContainer {
            PlaceItem {
                text: i18n("Countries")
                icon.name: "applications-internet" // HACK: tag-places is not colorful :/
                filter: "Countries"
            }
            PlaceItem {
                text: i18n("States")
                icon.name: "applications-internet"
                filter: "States"
            }
            PlaceItem {
                text: i18n("Cities")
                icon.name: "applications-internet"
                filter: "Cities"
            }
        }
        PlaceHeading {
            text: i18n("Time")
        }
        PlaceItemContainer {
            PlaceItem {
                text: i18n("Years")
                icon.name: "office-calendar" // view-calendar is not colorful
                filter: "Years"
            }
            PlaceItem {
                text: i18n("Months")
                icon.name: "office-calendar"
                filter: "Months"
            }
            PlaceItem {
                text: i18n("Weeks")
                icon.name: "office-calendar"
                filter: "Weeks"
            }
            PlaceItem {
                text: i18n("Days")
                icon.name: "office-calendar"
                filter: "Days"
            }
        }
        PlaceHeading {
            text: i18n("Tags")
            visible: applicationWindow().tags.length > 0
        }
        PlaceItemContainer {
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
}
