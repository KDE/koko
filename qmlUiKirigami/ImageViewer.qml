/*
 * Copyright (C) 2017 Marco Martin <mart@kde.org>
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * Copyright (C) 2015 Vishesh Handa <vhanda@kde.org>
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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.0 as Kirigami

Rectangle {
    id: root
    
    property alias model: listView.model
    property alias currentIndex: listView.currentIndex
    
    property int imageWidth
    property int imageHeight

    state: "closed"
    states: [
        State {
            name: "open"
            PropertyChanges {
                target: root
                visible: true
            }
            PropertyChanges {
                target: root
                opacity: 1
            }
        },
        State {
            name: "closed"
            PropertyChanges {
                target: root
                opacity: 0
            }
            PropertyChanges {
                target: root
                visible: false
            }
        }
    ]
    
    transitions: [
        Transition {
            from: "open"
            to: "closed"
            SequentialAnimation {
                OpacityAnimator {
                    target: root
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InQuad
                }
                PropertyAnimation {
                    target: root
                    property: "visible"
                    duration: Kirigami.Units.longDuration
                }
            }
        },
        Transition {
            from: "closed"
            to: "open"
            OpacityAnimator {
                target: root
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutQuad
            }
        }
    ]
    //NOTE: this is the only place where hardcoded black is fine
    color: "black"
        
    ListView {
        id: listView
        anchors.fill: parent
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        delegate: Flickable {
            id: flick
            width: imageWidth
            height: imageHeight
            contentWidth: imageWidth
            contentHeight: imageHeight
            interactive: contentWidth > width || contentHeight > height
            onInteractiveChanged: listView.interactive = !interactive;
            z: interactive ? 1000 : 0
            PinchArea {
                width: Math.max(flick.contentWidth, flick.width)
                height: Math.max(flick.contentHeight, flick.height)

                property real initialWidth
                property real initialHeight

                onPinchStarted: {
                    initialWidth = flick.contentWidth
                    initialHeight = flick.contentHeight
                }

                onPinchUpdated: {
                    // adjust content pos due to drag
                    flick.contentX += pinch.previousCenter.x - pinch.center.x
                    flick.contentY += pinch.previousCenter.y - pinch.center.y

                    // resize content
                    flick.resizeContent(Math.max(imageWidth, initialWidth * pinch.scale), Math.max(imageHeight, initialHeight * pinch.scale), pinch.center)
                }

                onPinchFinished: {
                    // Move its content within bounds.
                    flick.returnToBounds();
                }


                Image {
                    id: image
                    width: flick.contentWidth
                    height: flick.contentHeight
                    source: model.url
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize.width: imageWidth * 2
                    sourceSize.height: imageHeight * 2
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                            if (flick.interactive) {
                                flick.resizeContent(imageWidth, imageHeight, {x: imageWidth/2, y: imageHeight/2});
                            } else {
                                flick.resizeContent(imageWidth * 2, imageHeight * 2, {x: mouseX, y: mouseY});
                            }
                        }
                    }
                }
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
        onClicked: root.state = "closed"
    }
}
