/*
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.1
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1 as QQC2

import org.kde.kirigami 2.5 as Kirigami

Kirigami.GlobalDrawer {
    
    signal filterBy(string value)
    property Kirigami.Action previouslySelectedAction
    contentItem.implicitWidth: Kirigami.Units.gridUnit * 10

    modal: Kirigami.Settings.isMobile
    collapsible: true
    collapsed: Kirigami.Settings.isMobile
    bannerVisible: true

    header: Kirigami.AbstractApplicationHeader {
        Kirigami.Heading {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
            anchors.rightMargin: Kirigami.Units.smallSpacing * 2
            level: 2
            text: i18n("Sort by")
        }
    }


    actions: [
        Kirigami.Action {
            text: i18n("Locations")
            iconName: "tag-places"
            expandible: true

            Kirigami.Action {
                id: countryAction
                text: i18n("By Country")
                checkable: true
                onTriggered: {
                    filterBy("Countries")
                    previouslySelectedAction = countryAction
                }
            }
            Kirigami.Action {
                id: stateAction
                text: i18n("By State")
                checkable: true
                onTriggered: {
                    filterBy("States")
                    previouslySelectedAction = stateAction
                }
            }
            Kirigami.Action {
                id: cityAction
                text: i18n("By City")
                checkable: true
                onTriggered: {
                    filterBy("Cities")
                    previouslySelectedAction = cityAction
                }
            }
        },
        Kirigami.Action {
            text: i18n("Time")
            expandible: true
            iconName: "view-calendar"
            Kirigami.Action {
                id: yearAction
                text: i18n("By Year")
                checkable: true
                onTriggered: {
                    filterBy("Years")
                    previouslySelectedAction = yearAction
                }
            }
            Kirigami.Action {
                id: monthAction
                text: i18n("By Month")
                checkable: true
                onTriggered: {
                    filterBy("Months")
                    previouslySelectedAction = monthAction
                }
            }
            Kirigami.Action {
                id: weekAction
                text: i18n("By Week")
                checkable: true
                onTriggered: {
                    filterBy("Weeks")
                    previouslySelectedAction = weekAction
                }
            }
            Kirigami.Action {
                id: "dayAction"
                text: i18n("By Day")
                checkable: true
                onTriggered: {
                    filterBy("Days")
                    previouslySelectedAction = dayAction
                }
            }
        },
        Kirigami.Action {
            text: i18n("Path")
            expandible: true
            iconName: "folder-symbolic"
            Kirigami.Action {
                id: folderAction
                text: i18n("By Folder")
                checkable: true
                onTriggered: {
                    filterBy("Folders")
                    previouslySelectedAction = folderAction
                }
            }
        }
    ]

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
