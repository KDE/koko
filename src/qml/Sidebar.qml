/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.5 as Kirigami

Kirigami.GlobalDrawer {
    signal filterBy(string value)
    property var previouslySelectedAction

    // FIXME: Dirty workaround for 385992
    contentItem.implicitWidth: Kirigami.Units.gridUnit * 14

    // Autohiding behavior
    modal: !root.wideScreen
    onEnabledChanged: drawerOpen = enabled && !modal
    onModalChanged: drawerOpen = !modal

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    header: Kirigami.AbstractApplicationHeader {
        topPadding: Kirigami.Units.smallSpacing;
        bottomPadding: Kirigami.Units.smallSpacing;
        leftPadding: Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        Kirigami.Heading {
            level: 1
            text: i18n("Sort by")
        }
    }

    // Place
    QQC2.ScrollView {
        id: scrollView
        Layout.fillHeight: true
        Layout.fillWidth: true
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
            checkable: true
            separatorVisible: false
            Layout.fillWidth: true
            contentItem: Row {
                Kirigami.Icon {
                    source: item.icon
                    width: height
                    height: Kirigami.Units.iconSizes.small
                }
                QQC2.Label {
                    leftPadding: Kirigami.Units.smallSpacing
                    text: item.text
                }
            }
        }

        ColumnLayout {
            spacing: 1
            width: scrollView.width
            PlaceHeading {
                text: i18n("Locations")
            }
            PlaceItem {
                id: countryAction
                text: i18n("By Country")
                icon: "tag-places"
                onClicked: {
                    filterBy("Countries");
                    previouslySelectedAction = countryAction;
                }
            }
            PlaceItem {
                id: stateAction
                text: i18n("By State")
                icon: "tag-places"
                onClicked: {
                    filterBy("States");
                    previouslySelectedAction = stateAction;
                }
            }
            PlaceItem {
                id: cityAction
                text: i18n("By City")
                icon: "tag-places"
                onClicked: {
                    filterBy("Cities");
                    previouslySelectedAction = cityAction;
                }
            }
            PlaceHeading {
                text: i18n("Time")
            }
            PlaceItem {
                id: yearAction
                text: i18n("By Year")
                icon: "view-calendar"
                onClicked: {
                    filterBy("Years");
                    previouslySelectedAction = yearAction;
                }
            }
            PlaceItem {
                id: monthAction
                text: i18n("By Month")
                icon: "view-calendar"
                onClicked: {
                    filterBy("Months");
                    previouslySelectedAction = monthAction;
                }
            }
            PlaceItem {
                id: weekAction
                text: i18n("By Week")
                icon: "view-calendar"
                onClicked: {
                    filterBy("Weeks")
                    previouslySelectedAction = weekAction
                }
            }
            PlaceItem {
                id: dayAction
                text: i18n("By Day")
                icon: "view-calendar"
                onClicked: {
                    filterBy("Days")
                    previouslySelectedAction = dayAction
                }
            }
            PlaceHeading {
                text: i18n("Path")
            }
            PlaceItem {
                id: folderAction
                icon: "folder-symbolic"
                text: i18n("By Folder")
                onClicked: {
                    filterBy("Folders")
                    previouslySelectedAction = folderAction
                }
            }
        }
    }

    QQC2.Label {
        text: i18n("Thumbnails size:")
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
    }
    QQC2.Slider {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        from: Kirigami.Units.iconSizes.medium
        to: Kirigami.Units.iconSizes.enormous
        value: kokoConfig.iconSize
        onMoved: kokoConfig.iconSize = value;
    }

    Component.onCompleted: {
        folderAction.checked = true
        previouslySelectedAction = folderAction
    }
}
