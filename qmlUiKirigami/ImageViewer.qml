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
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.0 as Kirigami

Rectangle {
    id: root
    
    property alias listModel: listView.model
    property alias currentIndex: listView.currentIndex
    
    property int imageWidth

    //NOTE: this is the only place where hardcoded black is fine
    color: "black"
        
    ListView {
        id: listView
        anchors.fill: parent
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        delegate: Flickable {
            width: root.width
            height: root.height
            //TODO: zooming /flicking controls here, can be partly lifted from the old implementation
            Image {
                source: model.modelData
                sourceSize.width: imageWidth
                
            /*   MouseArea {
                    anchors.fill: parent
                    onClicked: console.log(model)
                }*/
            }
        }
    }

    onCurrentIndexChanged: {
        console.log("imageViewer changed currentIndex to "+ currentIndex)
        listView.positionViewAtIndex(currentIndex, ListView.Beginning)
    }
    //FIXME: placeholder, will have to use the state machine
    Controls.Button {
        text: "Back"
        onClicked: currentImage.model = null
    }
}
