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
import QtQuick.Window 2.2
import QtQuick.Controls 2.0 as Controls
import org.kde.kirigami 2.0 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.kquickcontrolsaddons 2.0 as KQA

Kirigami.Page {
    id: root
    
    property alias sourceModel: imagesListModel.sourceModel
    property int indexValue
    
    property int imageWidth
    property int imageHeight
    
    leftPadding: 0
    rightPadding: 0

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
            PropertyChanges {
                target: root
                focus: true
            }
            PropertyChanges {
                target: listView
                focus: true
            }
            PropertyChanges {
                target: applicationWindow()
                visibility: Window.Windowed
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
        },
        State {
            name: "fullscreen"
            PropertyChanges {
                target: root
                focus: true
            }
            PropertyChanges {
                target: listView
                focus: true
            }
            PropertyChanges {
                target: applicationWindow()
                visibility: Window.FullScreen
            }
        }
    ]
    
    transitions: [
        Transition {
            from: "*"
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
                ScriptAction {
                    script: applicationWindow().pageStack.forceActiveFocus();
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
    
    background: Rectangle {
        color: "black"
    }

    Keys.onPressed: {
        switch(event.key) {
            case Qt.Key_Escape:
                root.state = "closed"
                break;
            case Qt.Key_F:
                root.state = root.state == "open" ? "fullscreen" : "open"
                break;
            default:
                break;
        }
    }
    
    ListView {
        id: listView
        anchors.fill: parent
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        onMovementEnded: currentImage.index = model.sourceIndex(indexAt(contentX+1, 1))
        
        model: Koko.SortModel {
            id: imagesListModel
            filterRole: Koko.Roles.MimeTypeRole
            filterRegExp: /image\//
        }
        currentIndex: model.proxyIndex( indexValue)
        
        Timer {
            id: timer
            interval: 2000
            onTriggered: footerList.opacity = 0
        }
        
        onCurrentIndexChanged: {
            currentImage.index = model.sourceIndex( currentIndex)
            listView.positionViewAtIndex(currentIndex, ListView.Beginning)
            footerList.opacity = 1.0
            timer.restart()
        }

        delegate: Flickable {
            id: flick
            width: imageWidth
            height: imageHeight
            contentWidth: imageWidth
            contentHeight: imageHeight
            interactive: contentWidth > width || contentHeight > height
            onInteractiveChanged: listView.interactive = !interactive;
            clip: true
            z: index == listView.currentIndex ? 1000 : 0

            Controls.ScrollBar.vertical: Controls.ScrollBar {}
            Controls.ScrollBar.horizontal: Controls.ScrollBar {}

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
                    flick.resizeContent(Math.max(imageWidth*0.7, initialWidth * pinch.scale), Math.max(imageHeight*0.7, initialHeight * pinch.scale), pinch.center)
                }

                onPinchFinished: {
                    // Move its content within bounds.
                    if (flick.contentWidth < root.imageWidth || 
                        flick.contentHeight < root.imageHeight) {
                        zoomAnim.x = 0;
                        zoomAnim.y = 0;
                        zoomAnim.width = root.imageWidth;
                        zoomAnim.height = root.imageHeight;
                        zoomAnim.running = true;
                    } else {
                        flick.returnToBounds();
                    }
                }

                ParallelAnimation {
                    id: zoomAnim
                    property real x: 0
                    property real y: 0
                    property real width: root.imageWidth
                    property real height: root.imageHeight
                    NumberAnimation {
                        target: flick
                        property: "contentWidth"
                        from: flick.contentWidth
                        to: zoomAnim.width
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad 
                    }
                    NumberAnimation {
                        target: flick
                        property: "contentHeight"
                        from: flick.contentHeight
                        to: zoomAnim.height
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad 
                    }
                    NumberAnimation {
                        target: flick
                        property: "contentY"
                        from: flick.contentY
                        to: zoomAnim.y
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad 
                    }
                    NumberAnimation {
                        target: flick
                        property: "contentX"
                        from: flick.contentX
                        to: zoomAnim.x
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad 
                    }
                }

                Image {
                    id: image
                    width: flick.contentWidth
                    height: flick.contentHeight
                    source: model.imageurl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    autoTransform: true
                    sourceSize.width: imageWidth * 2
                    sourceSize.height: imageHeight * 2
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                            if (flick.interactive) {
                                zoomAnim.x = 0;
                                zoomAnim.y = 0;
                                zoomAnim.width = root.imageWidth;
                                zoomAnim.height = root.imageHeight;
                                zoomAnim.running = true;
                            } else {
                                zoomAnim.x = mouse.x * 2;
                                zoomAnim.y = mouse.y *2;
                                zoomAnim.width = root.imageWidth * 3;
                                zoomAnim.height = root.imageHeight * 3;
                                zoomAnim.running = true;
                            }
                        }
                        onWheel: {
                            if (wheel.modifiers & Qt.ControlModifier) {
                                if (wheel.angleDelta.y != 0) {
                                    var factor = 1 + wheel.angleDelta.y / 600;
                                    zoomAnim.running = false;

                                    zoomAnim.width = Math.min(Math.max(root.imageWidth, zoomAnim.width * factor), root.imageWidth * 4);
                                    zoomAnim.height = Math.min(Math.max(root.imageHeight, zoomAnim.height * factor), root.imageHeight * 4);

                                    //actual factors, may be less than factor
                                    var xFactor = zoomAnim.width / flick.contentWidth;
                                    var yFactor = zoomAnim.height / flick.contentHeight;

                                    zoomAnim.x = flick.contentX * xFactor + (((wheel.x - flick.contentX) * xFactor) - (wheel.x - flick.contentX))
                                    zoomAnim.y = flick.contentY * yFactor + (((wheel.y - flick.contentY) * yFactor) - (wheel.y - flick.contentY))
                                    zoomAnim.running = true;

                                } else if (wheel.pixelDelta.y != 0) {
                                    flick.resizeContent(Math.min(Math.max(root.imageWidth, flick.contentWidth + wheel.pixelDelta.y), root.imageWidth * 4),
                                                        Math.min(Math.max(root.imageHeight, flick.contentHeight + wheel.pixelDelta.y), root.imageHeight * 4),
                                                        wheel);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    PathView {
        id: footerList
        height: Kirigami.Units.gridUnit * 4
        model: listView.model
        currentIndex: listView.currentIndex
        pathItemCount: applicationWindow().width / (Kirigami.Units.gridUnit * 5)
        interactive: false
        
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        
        Behavior on opacity { OpacityAnimator { duration: 500}}
        
        path: Path {
            startX: 0
            startY: applicationWindow().height - (Kirigami.Units.gridUnit * 5)
            PathAttribute { name: "iconScale"; value: 0.5 }
            PathLine {
                x: applicationWindow().width / 2
                y: applicationWindow().height - (Kirigami.Units.gridUnit * 5)
            }
            PathAttribute { name: "iconScale"; value: 1.5 }
            PathLine { 
                x: applicationWindow().width
                y: applicationWindow().height - (Kirigami.Units.gridUnit * 5)
            }
            PathAttribute { name: "iconScale"; value: 0.5 }
        }
        
        delegate: Item {
            scale: PathView.iconScale
            height: Kirigami.Units.gridUnit * 4
            width: height
            KQA.QImageItem {
                height: Kirigami.Units.gridUnit * 3.8
                width: height
                anchors.centerIn: parent
                image: model.thumbnail
            }
        }
    }
    
    //FIXME: placeholder, will have to use the state machine
    Controls.Button {
        text: i18n("Back")
        onClicked: root.state = "closed"
    }
}
