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

import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.10 as Controls
import QtGraphicalEffects 1.0 as Effects
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.13 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.kquickcontrolsaddons 2.0 as KQA

Kirigami.Page {
    id: root

    title: listView.currentItem.display
    property alias sourceModel: imagesListModel.sourceModel
    property int indexValue
    
    property int imageWidth
    property int imageHeight
    
    leftPadding: 0
    rightPadding: 0
    topPadding: 0

    Kirigami.Theme.inherit: false
    Kirigami.Theme.textColor: imgColors.foreground
    Kirigami.Theme.backgroundColor: imgColors.background
    Kirigami.Theme.highlightColor: imgColors.highlight
    Kirigami.Theme.highlightedTextColor: Kirigami.ColorUtils.brightnessForColor(imgColors.highlight) === Kirigami.ColorUtils.Dark ? imgColors.closestToWhite : imgColors.closestToBlack

    Kirigami.ImageColors {
        id: imgColors
        source: listView.currentItem
    }

    KQA.MimeDatabase {
        id: mimeDB
    }
    
    Kirigami.ContextDrawer {
        id: contextDrawer
        title: i18n("Edit image")
        handleVisible: true
    }
    
    actions {
        main: Kirigami.Action {
            id: shareAction
            iconName: "document-share"
            tooltip: i18n("Share Image")
            text: i18nc("verb, share an image", "Share")
            onTriggered: {
                shareDialog.open();
                shareDialog.inputData = {
                    "urls": [ listView.currentItem.currentImageSource.toString() ],
                    "mimeType": mimeDB.mimeTypeForUrl( listView.currentItem.currentImageSource).name
                }
            }
        }
        right: Kirigami.Action {
            id: editingAction
            iconName: "edit-entry"
            text: i18nc("verb, edit an image", "Edit")
            onTriggered: {
                applicationWindow().pageStack.layers.push(editorComponent)
            }
        }
    }
    

    Component.onCompleted: {
        applicationWindow().controlsVisible = false;
        listView.forceActiveFocus();
        applicationWindow().header.visible = false;
        applicationWindow().footer.visible = false;
        applicationWindow().globalDrawer.visible = false;
        applicationWindow().globalDrawer.enabled = false;
    }
    function close() {
        applicationWindow().controlsVisible = true;
        if (applicationWindow().footer) {
            applicationWindow().footer.visible = true;
        }
        applicationWindow().globalDrawer.enabled = true;
        applicationWindow().visibility = Window.Windowed;
        applicationWindow().pageStack.layers.pop();
    }

    
    background: Rectangle {
        color: "black"
    }

    Keys.onPressed: {
        switch(event.key) {
            case Qt.Key_Escape:
                root.close();
                break;
            case Qt.Key_F:
                applicationWindow().visibility = applicationWindow().visibility == Window.FullScreen ? Window.Windowed : Window.FullScreen
                break;
            default:
                break;
        }
    }

    ShareDialog {
        id: shareDialog

        inputData: {
            "urls": [],
            "mimeType": ["image/"]
        }
        onFinished: {
            if (error==0 && output.url !== "") {
                console.assert(output.url !== undefined);
                var resultUrl = output.url;
                console.log("Received", resultUrl)
                notificationManager.showNotification( true, resultUrl);
                clipboard.content = resultUrl;
            } else {
                notificationManager.showNotification( false);
            }
        }
    }

    ListView {
        id: thumbnailView
        z: 100
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        state: applicationWindow().controlsVisible ? "show" : "hidden"

        states: [
            State {
                name: "show"
                PropertyChanges { target: thumbnailView; opacity: 1.0 }
                PropertyChanges { target: thumbnailView; anchors.bottomMargin: 0 }
            },
            State {
                name: "hidden"
                PropertyChanges { target: thumbnailView; opacity: 0.0 }
                PropertyChanges { target: thumbnailView; anchors.bottomMargin: -thumbnailView.height  }
            }
        ]

        transitions: [
            Transition {
                from: "*"
                to: "hidden"
                SequentialAnimation {
                    PropertyAnimation {
                        properties: "opacity,anchors.bottomMargin";
                        easing.type: Easing.InCubic
                        duration: Kirigami.Units.longDuration
                    }
                    PropertyAction {
                        target: thumbnailView
                        property: "visible"
                        value: false
                    }
                }
            },
            Transition {
                from: "*"
                to: "show"
                SequentialAnimation {
                    PropertyAction {
                        target: thumbnailView
                        property: "visible"
                        value: true
                    }
                    PropertyAnimation {
                        properties: "opacity,anchors.bottomMargin";
                        easing.type: Easing.OutCubic
                        duration: Kirigami.Units.longDuration * 0.75
                    }
                }
            }
        ]

        height: kokoConfig.iconSize
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        currentIndex: listView.currentIndex

        highlightRangeMode: ListView.ApplyRange
        highlightFollowsCurrentItem: true
        preferredHighlightBegin: height
        preferredHighlightEnd: width - height
        highlightMoveVelocity: -1
        highlightMoveDuration: Kirigami.Units.longDuration

        model: Koko.SortModel {
            sourceModel: root.sourceModel
            filterRole: Koko.Roles.MimeTypeRole
            filterRegExp: /image\//
        }
        delegate: AlbumDelegate {
            width: kokoConfig.iconSize + Kirigami.Units.largeSpacing
            height: width
            onClicked: activated()
            onActivated: listView.currentIndex = index
            modelData: model

            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
                border.color: Kirigami.Theme.highlightColor
                radius: 2
                opacity: thumbnailView.currentIndex === index ? 1 : 0
                Behavior on opacity {
                    OpacityAnimator {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        onMovementEnded: currentImage.index = model.sourceIndex(indexAt(contentX+1, 1))
        interactive: true

        model: Koko.SortModel {
            id: imagesListModel
            filterRole: Koko.Roles.MimeTypeRole
            filterRegExp: /image\//
        }

        Binding {
            target: listView
            property: "currentIndex"
            value: listView.model.proxyIndex( indexValue)
        }
        
        onCurrentIndexChanged: {
            currentImage.index = model.sourceIndex( currentIndex)
            listView.positionViewAtIndex(currentIndex, ListView.Beginning)

            shareDialog.close();
        }

        delegate: Flickable {
            id: flick
            readonly property string currentImageSource: model.imageurl
            readonly property string display: model.display
            property alias image: image
            width: imageWidth
            height: imageHeight
            contentWidth: imageWidth
            contentHeight: imageHeight
            boundsBehavior: Flickable.StopAtBounds
            boundsMovement: Flickable.StopAtBounds
            interactive: contentWidth > width || contentHeight > height
            //onInteractiveChanged: listView.interactive = !interactive;
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
                    fillMode: Image.PreserveAspectFit
                    source: currentImageSource
                    autoTransform: true
                    asynchronous: true
                    onStatusChanged: {
                        if (status === Image.Ready && listView.currentIndex === index) {
                            imgColors.update();
                        }
                    }
                    Timer {
                        id: doubleClickTimer
                        interval: 150
                        onTriggered: applicationWindow().controlsVisible = !applicationWindow().controlsVisible
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            contextDrawer.drawerOpen = false
                            doubleClickTimer.restart();
                        }
                        onDoubleClicked: {
                            doubleClickTimer.running = false;
                            applicationWindow().controlsVisible = false;
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

    Controls.RoundButton {
        anchors {
          left: parent.left
          leftMargin: Kirigami.Units.largeSpacing
          verticalCenter: parent.verticalCenter
        }
        width: Kirigami.Units.gridUnit * 2
        height: width
        icon.name: "arrow-left"
        visible: !Kirigami.Settings.isMobile && applicationWindow().controlsVisible
        Keys.forwardTo: [listView]
        onClicked: {
            listView.currentIndex -= 1
        }
    }

    Controls.RoundButton {
        anchors {
          right: parent.right
          rightMargin: Kirigami.Units.largeSpacing
          verticalCenter: parent.verticalCenter
        }
        width: Kirigami.Units.gridUnit * 2
        height: width
        icon.name: "arrow-right"
        visible: !Kirigami.Settings.isMobile && applicationWindow().controlsVisible
        Keys.forwardTo: [listView]
        onClicked: {
            listView.currentIndex += 1
        }
    }
    
    Component {
        id: editorComponent
        EditorView {
            width: root.imageWidth
            height: root.imageHeight
            imagePath: listView.currentItem.currentImageSource
        }
    }
    
}
