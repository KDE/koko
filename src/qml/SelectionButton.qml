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
