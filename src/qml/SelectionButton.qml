/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.7

import org.kde.kirigami 2.1 as Kirigami
import org.kde.koko 0.1 as Koko

Kirigami.Icon {
    id: iconArea
    property QtObject iconMouseArea: iconMouseArea
    width: Kirigami.Units.iconSizes.smallMedium
    height: width
    z: gridView.z + 2

    MouseArea {
        id: iconMouseArea
        anchors.fill: parent
        state: "add"
        onClicked: { 
            if(iconMouseArea.state == "add") {
                gridView.model.setSelected(model.index)
            } else {
                gridView.model.toggleSelected(model.index)
            }
        }
        
        states: [
            State {
                name: "add"
                when: !model.selected
                PropertyChanges {
                    target: iconArea
                    source: "emblem-added"
                }
            },
            State {
                name: "remove"
                when: model.selected
                PropertyChanges {
                    target: iconArea
                    source: "emblem-remove"
                }
            }
        ]
    }
}
