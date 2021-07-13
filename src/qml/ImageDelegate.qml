/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Window 2.2
import QtQuick.Controls 2.10 as Controls
import QtGraphicalEffects 1.0 as Effects
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.13 as Kirigami
import org.kde.koko 0.1 as Koko

Flickable {
    id: flick
    property string currentImageSource
    property string currentImageMimeType

    contentWidth: width
    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    boundsMovement: Flickable.StopAtBounds
    interactive: contentWidth > width || contentHeight > height
    clip: true

    Controls.ScrollBar.vertical: Controls.ScrollBar {
        visible: !applicationWindow().controlsVisible && flick.interactive
    }
    Controls.ScrollBar.horizontal: Controls.ScrollBar {
        visible: !applicationWindow().controlsVisible && flick.interactive
    }

    property bool autoplay: false
    onAutoplayChanged: {
        if (autoplay && videoLoader.status == Loader.Ready) { // play video automatically if started with "open with..."
            videoLoader.item.play();
            autoplay = false;
        }
    }

    property bool isCurrentImage: ListView.isCurrentItem
    onIsCurrentImageChanged: {
        if (isCurrentImage) {
            if (listView.slideshow.running) {
                if (videoLoader.status == Loader.Ready) { // play video automatically if slideshow is running
                    videoLoader.item.play();
                } else if (listView.slideshow.externalMediaRunning) {
                    // indicate playback being finished if delegate that started it was unloaded (i.e. by using thumbnail bar)
                    listView.slideshow.externalPlaybackUnloaded();
                }
            }
            return
        }
        // stop video/zoom out if image is no longer current
        if (videoLoader.status == Loader.Ready) {
            videoLoader.item.player.stop();
        }
        if (flick.interactive) {
            flick.contentWidth = root.width;
            flick.contentHeight = root.height;
            flick.contentX = 0;
            flick.contentY = 0;
        }
    }

    Component {
        id: videoPlayer
        VideoPlayer {
            width: Math.max(flick.contentWidth, flick.width)
            height: Math.max(flick.contentHeight, flick.height)
            source: currentImageSource
        }
    }

    Loader {
        id: videoLoader
        active: currentImageMimeType.startsWith("video/")
        sourceComponent: videoPlayer
        onLoaded: {
            // in case loader takes it's sweet time to load
            if (flick.autoplay || (listView.slideshow.running && flick.isCurrentImage)) {
                videoLoader.item.play();
                flick.autoplay = false;
            }
        }
    }

    Connections {
        target: listView.slideshow
        function onRunningChanged() {
            // start playback if slideshow is running
            if (listView.slideshow.running && flick.isCurrentImage) {
                if (videoLoader.item.playing) { // indicate that video is already playing
                    listView.slideshow.externalPlaybackStarted();
                } else {
                    videoLoader.item.play();
                }
            }
        }
    }

    Connections {
        target: videoLoader.item
        function onPlaybackStarted() {
            if (!flick.isCurrentImage) {
                return;
            }
            // indicate that we're running a video
            if (listView.slideshow.running) {
                listView.slideshow.externalPlaybackStarted();
            }
        }
        function onPlaybackFinished() {
            if (!flick.isCurrentImage) {
                return;
            }
            // indicate that we stopped playing the video
            if (listView.slideshow.externalMediaRunning) {
                listView.slideshow.externalPlaybackFinished();
            }
        }
    }

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
            flick.resizeContent(Math.max(root.width*0.7, initialWidth * pinch.scale), Math.max(root.height*0.7, initialHeight * pinch.scale), pinch.center)
        }

        onPinchFinished: {
            // Move its content within bounds.
            if (flick.contentWidth < root.width ||
                flick.contentHeight < root.height) {
                zoomAnim.x = 0;
                zoomAnim.y = 0;
                zoomAnim.width = root.width;
                zoomAnim.height = root.height;
                zoomAnim.running = true;
            } else {
                flick.returnToBounds();
            }
        }

        ParallelAnimation {
            id: zoomAnim
            property real x: 0
            property real y: 0
            property real width: root.width
            property real height: root.height
            NumberAnimation {
                target: flick
                property: "contentWidth"
                from: flick.contentWidth
                to: zoomAnim.width
                duration: Kirigami.Units.veryShortDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: flick
                property: "contentHeight"
                from: flick.contentHeight
                to: zoomAnim.height
                duration: Kirigami.Units.veryShortDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: flick
                property: "contentY"
                from: flick.contentY
                to: zoomAnim.y
                duration: Kirigami.Units.veryShortDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: flick
                property: "contentX"
                from: flick.contentX
                to: zoomAnim.x
                duration: Kirigami.Units.veryShortDuration
                easing.type: Easing.InOutQuad
            }
        }
        Image {
            id: image
            width: flick.contentWidth
            height: flick.contentHeight
            fillMode: Image.PreserveAspectFit
            source: !currentImageMimeType.startsWith("video/") && !currentImageSource.endsWith(".gif") ? currentImageSource : ""
            autoTransform: true
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready && listView.currentIndex === index) {
                    imgColors.update();
                }
            }
        }
        // sadly sourceSize is read only in AnimatedImage, so we keep it separate
        AnimatedImage {
            id: imageAnimated
            width: flick.contentWidth
            height: flick.contentHeight
            fillMode: Image.PreserveAspectFit
            source: !currentImageMimeType.startsWith("video/") && currentImageSource.endsWith(".gif") ? currentImageSource : ""
            autoTransform: true
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready && listView.currentIndex === index) {
                    imgColors.update();
                }
            }
        }
        Timer {
            id: doubleClickTimer
            interval: 150
            onTriggered: applicationWindow().controlsVisible = !applicationWindow().controlsVisible
        }
        MouseArea {
            anchors.fill: image
            enabled: !currentImageMimeType.startsWith("video/")
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
                    zoomAnim.width = root.width;
                    zoomAnim.height = root.height;
                    zoomAnim.running = true;
                } else {
                    zoomAnim.x = mouse.x * 2;
                    zoomAnim.y = mouse.y *2;
                    zoomAnim.width = root.width * 3;
                    zoomAnim.height = root.height * 3;
                    zoomAnim.running = true;
                }
            }
            onWheel: {
                if (wheel.modifiers & Qt.ControlModifier) {
                    if (wheel.pixelDelta.y !== 0) {
                        flick.contentX += wheel.pixelDelta.x;
                        flick.contentY += wheel.pixelDelta.y;
                    } else {
                        flick.contentX -= wheel.angleDelta.x;
                        flick.contentY -= wheel.angleDelta.y;
                    }
                } else {
                    if (wheel.angleDelta.y !== 0) {
                        var factor = 1 + wheel.angleDelta.y / 600;
                        zoomAnim.running = false;

                        zoomAnim.width = Math.min(Math.max(root.width, zoomAnim.width * factor), root.width * 4);
                        zoomAnim.height = Math.min(Math.max(root.height, zoomAnim.height * factor), root.height * 4);

                        //actual factors, may be less than factor
                        var xFactor = zoomAnim.width / flick.contentWidth;
                        var yFactor = zoomAnim.height / flick.contentHeight;

                        zoomAnim.x = flick.contentX * xFactor + (((wheel.x - flick.contentX) * xFactor) - (wheel.x - flick.contentX))
                        zoomAnim.y = flick.contentY * yFactor + (((wheel.y - flick.contentY) * yFactor) - (wheel.y - flick.contentY))
                        zoomAnim.running = true;

                    } else if (wheel.pixelDelta.y !== 0) {
                        flick.resizeContent(Math.min(Math.max(root.width, flick.contentWidth + wheel.pixelDelta.y), root.width * 4),
                                            Math.min(Math.max(root.height, flick.contentHeight + wheel.pixelDelta.y), root.height * 4),
                                            wheel);
                    }
                }
            }
        }
    }
    Controls.BusyIndicator {
        id: busyIndicator
        parent: flick
        anchors.centerIn: parent
        visible: running
        running: image.status === Image.Loading || imageAnimated.status === Image.Loading
        background: Rectangle {
            radius: height/2
            color: busyIndicator.palette.base
        }
        SequentialAnimation {
            running: busyIndicator.running
            PropertyAction {
                target: busyIndicator
                property: "opacity"
                value: 0
            }
            // Don't show if the waiting time is pretty short.
            // If we had some way to predict how long it might take,
            // it would be better to use that to decide whether or not
            // to show the BusyIndicator.
            PauseAnimation {
                duration: 200
            }
            NumberAnimation {
                target: busyIndicator
                property: "opacity"
                from: 0
                to: 1
                duration: Kirigami.Units.veryLongDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
