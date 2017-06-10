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
import QtQuick.Controls 2.1 as Controls

import org.kde.kirigami 2.1 as Kirigami

Kirigami.GlobalDrawer {
    
    signal filterBy(string value)
    property string previouslySelectedAction
    
    title: qsTr("Navigation") 
    
    actions: [
        Kirigami.Action {
            text: qsTr("Locations")
            enabled: false
        },
        Kirigami.Action {
            id: countryAction
            text: qsTr("By Country")
            checkable: true
            onTriggered: {
                filterBy("Countries")
                previouslySelectedAction = "countryAction"
            }
        },
        Kirigami.Action {
            id: stateAction
            text: qsTr("By State")
            checkable: true
            onTriggered: {
                filterBy("States")
                previouslySelectedAction = "stateAction"
            }
        },
        Kirigami.Action {
            id: cityAction
            text: qsTr("By City")
            checkable: true
            onTriggered: {
                filterBy("Cities")
                previouslySelectedAction = "cityAction"
            }
        },
        Kirigami.Action {
            text: qsTr("Time")
            enabled: false
        },
        Kirigami.Action {
            id: yearAction
            text: qsTr("By Year")
            checkable: true
            onTriggered: {
                filterBy("Years")
                previouslySelectedAction = "yearAction"
            }
        },
        Kirigami.Action {
            id: monthAction
            text: qsTr("By month")
            checkable: true
            onTriggered: {
                filterBy("Months")
                previouslySelectedAction = "monthAction"
            }
        },
        Kirigami.Action {
            id: weekAction
            text: qsTr("By Week")
            checkable: true
            onTriggered: {
                filterBy("Weeks")
                previouslySelectedAction = "weekAction"
            }
        },
        Kirigami.Action {
            id: "dayAction"
            text: qsTr("By Day")
            checkable: true
            onTriggered: {
                filterBy("Days")
                previouslySelectedAction = "dayAction"
            }
        },
        Kirigami.Action {
            text: qsTr("Path")
            enabled: false
        },
        Kirigami.Action {
            id: folderAction
            text: qsTr("By Folder")
            checkable: true
            onTriggered: {
                filterBy("Folders")
                previouslySelectedAction = "folderAction"
            }
        }
    ]      
    
    function findAction(value) {
        switch(value) {
            case "countryAction": return countryAction
            case "stateAction": return stateAction
            case "cityAction": return cityAction
            case "yearAction": return yearAction
            case "monthAction": return monthAction
            case "weekAction": return weekAction
            case "dayAction": return dayAction
            case "folderAction": return folderAction
        }
    }
}
