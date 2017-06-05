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

Kirigami.ScrollablePage {
    
    property alias model: gridView.model
    signal imageClicked(var files)
    
    GridView {
        id: gridView
        
        property int iconSize: Kirigami.Units.iconSizes.enormous
        
        cellWidth: width / Math.floor(width / (iconSize + Kirigami.Units.largeSpacing*2))
        cellHeight: iconSize + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing*2
        
        delegate: FocusScope {
            
            Image {
                source: model.cover
                width: gridView.cellWidth - Kirigami.Units.largeSpacing
                height: gridView.cellHeight - Kirigami.Units.largeSpacing
                
                fillMode: Image.PreserveAspectCrop
                
                MouseArea {
                    anchors.fill: parent 
                    onClicked: {
                        imageClicked(model.files)
                    }
                }
            }
            
            Kirigami.BasicListItem {
                label: model.fileCount == 1 ? qsTr(" %1 \n 1 Image").arg(model.display) : qsTr(" %1 \n %2 Images").arg(model.display).arg(model.fileCount);
                reserveSpaceForIcon: false
                width: gridView.cellWidth - Kirigami.Units.smallSpacing
                background: Rectangle {
                    anchors.fill: parent
                    opacity: 0.7
                    color: Kirigami.Theme.backgroundColor
                }
            }
        }
    }
    
}
