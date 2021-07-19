/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as Controls
import QtGraphicalEffects 1.15 as Effects
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1

Flickable {
    id: flick
    property string currentImageSource
    property string currentImageMimeType
    property Item listView
    property VideoPlayer videoPlayer: null
    property AnimatedImage animatedImage: null
    property Image image: null
    readonly property Item media: videoPlayer || animatedImage || image
    // get info from Exiv2Extractor
    property real mediaSourceWidth: 0
    property real mediaSourceHeight: 0
    property real zoomFactor: (videoPlayer ? videoPlayer.implicitWidth : media.paintedWidth) / mediaSourceWidth

    function defaultContentWidth() {
        return media ? Math.min(mediaSourceWidth, width) : width
    }
    function defaultContentHeight() {
        return media ? Math.min(mediaSourceHeight, height) : height
    }
    // contentItem.x and contentItem.y work like normal item x and y values
    // while contentX and contentY are the same, but with flipped signs.
    // contentX == -contentItem.x and contentY == -contentItem.y
    function centerContentX() {
        return -(flick.width - flick.contentWidth) / 2
    }
    function centerContentY() {
        return -(flick.height - flick.contentHeight) / 2
    }
    function test(centerX, contentWidth, oldContentWidth) {
        const newX = centerX * contentWidth / oldContentWidth;
        flick.contentX = (contentX + newX - centerX);
    }

    contentWidth: defaultContentWidth()
    contentHeight: defaultContentHeight()
    contentX: 0//centerContentX()
    contentY: 0//centerContentY()
    boundsBehavior: Flickable.StopAtBounds
    boundsMovement: Flickable.StopAtBounds
    interactive: contentWidth > width || contentHeight > height
    clip: true
    pixelAligned: true
    maximumFlickVelocity: 0

    Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {
        visible: !applicationWindow().controlsVisible && flick.interactive
    }
    Controls.ScrollIndicator.horizontal: Controls.ScrollIndicator {
        visible: !applicationWindow().controlsVisible && flick.interactive
    }

    property bool autoplay: false
    onAutoplayChanged: {
        if (autoplay && videoPlayer) { // play video automatically if started with "open with..."
            videoPlayer.play();
            autoplay = false;
        }
    }

    property bool isCurrentImage: ListView.isCurrentItem
    onIsCurrentImageChanged: {
        //resizeContent()
        if (isCurrentImage) {
            if (listView.slideshow.running) {
                if (videoPlayer) { // play video automatically if slideshow is running
                    videoPlayer.play();
                } else if (listView.slideshow.externalMediaRunning) {
                    // indicate playback being finished if delegate that started it was unloaded (i.e. by using thumbnail bar)
                    listView.slideshow.externalPlaybackUnloaded();
                }
            }
            return
        }
        // stop video/zoom out if image is no longer current
        if (videoPlayer) {
            videoPlayer.player.stop();
        }
    }

    Component {
        id: videoPlayerComponent
        VideoPlayer {
            anchors.fill: parent
            source: currentImageSource
            onPlaybackStarted: {
                if (!flick.isCurrentImage) {
                    return;
                }
                // indicate that we're running a video
                if (listView.slideshow.running) {
                    listView.slideshow.externalPlaybackStarted();
                }
            }
            onPlaybackFinished: {
                if (!flick.isCurrentImage) {
                    return;
                }
                // indicate that we stopped playing the video
                if (listView.slideshow.externalMediaRunning) {
                    listView.slideshow.externalPlaybackFinished();
                }
            }
            // in case loader takes it's sweet time to load
            Component.onCompleted: if (flick.autoplay
                || (listView.slideshow.running && flick.isCurrentImage)) {
                play();
                flick.autoplay = false;
            }
        }
    }

    Component {
        id: animatedImageComponent
        // sadly sourceSize is read only in AnimatedImage, so we keep it separate
        AnimatedImage {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: currentImageSource
            autoTransform: true
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready && listView.currentIndex === index) {
                    imgColors.update();
                }
            }
        }
    }

    Component {
        id: imageComponent
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: currentImageSource
            autoTransform: true
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready && listView.currentIndex === index) {
                    imgColors.update();
                }
            }
        }
    }

    onCurrentImageMimeTypeChanged: if (currentImageMimeType.startsWith("video/")
        && videoPlayer === null) {
        videoPlayer = videoPlayerComponent.createObject(flick.contentItem)
        animatedImage = null
        image = null
    } else if (currentImageSource.endsWith(".gif") && animatedImage === null) {
        videoPlayer = null
        animatedImage = animatedImageComponent.createObject(flick.contentItem)
        image = null
    } else {
        videoPlayer = null
        animatedImage = null
        image = imageComponent.createObject(flick.contentItem)
    }

    Connections {
        target: listView.slideshow
        function onRunningChanged() {
            // start playback if slideshow is running
            if (listView.slideshow.running && flick.isCurrentImage && videoPlayer) {
                if (videoPlayer.playing) { // indicate that video is already playing
                    listView.slideshow.externalPlaybackStarted();
                } else {
                    videoPlayer.play();
                }
            }
        }
    }

    ParallelAnimation {
        id: zoomAnim
        property real x: flick.contentX
        property real y: flick.contentY
        property real width: flick.contentWidth
        property real height: flick.contentHeight
        SmoothedAnimation {
            target: flick
            property: "contentWidth"
            from: flick.contentWidth
            to: zoomAnim.width
            duration: Kirigami.Units.longDuration
        }
        SmoothedAnimation {
            target: flick
            property: "contentHeight"
            from: flick.contentHeight
            to: zoomAnim.height
            duration: Kirigami.Units.longDuration
        }
        SmoothedAnimation {
            target: flick.contentItem
            property: "y"
            from: flick.contentY
            to: zoomAnim.y
            duration: Kirigami.Units.longDuration
        }
        SmoothedAnimation {
            target: flick.contentItem
            property: "x"
            from: flick.contentX
            to: zoomAnim.x
            duration: Kirigami.Units.longDuration
        }
    }

    PinchArea {
        anchors.fill: parent
        parent: flick
//         width: Math.max(flick.contentWidth, flick.width)
//         height: Math.max(flick.contentHeight, flick.height)

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
            flick.resizeContent(Math.max(flick.width*0.7, initialWidth * pinch.scale),
                                Math.max(flick.height*0.7, initialHeight * pinch.scale),
                                pinch.center)
        }

        onPinchFinished: {
            // Move its content within bounds.
            if (flick.contentWidth < flick.width
                || flick.contentHeight < flick.height) {
                if (flick.contentWidth < flick.mediaSourceWidth
                    || flick.contentHeight < flick.mediaSourceHeight) {
                    flick.contentWidth = mediaSourceWidth
                    flick.contentHeight = mediaSourceHeight
                }
                flick.contentX = -(flick.width - flick.contentWidth) / 2;
                flick.contentY = -(flick.height - flick.contentHeight) / 2;
            } else {
                flick.returnToBounds();
            }
        }
    }

    Timer {
        id: doubleClickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval + 1
        onTriggered: applicationWindow().controlsVisible = !applicationWindow().controlsVisible
    }

    MouseArea {
        id: mouseArea
        property real totalPixelDelta: 0
        property bool zoomed: false
        parent: flick
        cursorShape: pressed || flick.dragging || flick.listView.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        anchors.fill: parent
        enabled: !flick.videoPlayer

        function angleDeltaToPixels(delta) {
            // 120 units == 1 step; steps * line height * lines per step
            return delta / 120 * Kirigami.Units.gridUnit * Qt.styleHints.wheelScrollLines
        }
        function contentWidthForPixelDelta(delta) {
            return Math.min(Math.max(Math.min(flick.mediaSourceWidth, flick.width), // min
                                     contentWidth + delta),
                                     flick.mediaSourceWidth * 16) // max
        }
        function contentHeightForPixelDelta(delta) {
            return Math.min(Math.max(Math.min(flick.mediaSourceHeight, flick.height), // min
                                     contentHeight + delta),
                                     flick.mediaSourceHeight * 16) // max
        }

        onClicked: {
            contextDrawer.drawerOpen = false
            doubleClickTimer.restart();
        }

        onDoubleClicked: {
            doubleClickTimer.running = false;
            if (Kirigami.Settings.isMobile) { applicationWindow().controlsVisible = false }
            if (zoomed || flick.interactive) {
                zoomed = false
                flick.contentWidth = defaultContentWidth()
                flick.contentHeight = defaultContentHeight()
                flick.contentX = -(flick.width - flick.contentWidth) / 2
                flick.contentY = -(flick.height - flick.contentHeight) / 2
            } else if (!zoomed) {
                zoomed = true
                flick.contentWidth *= 2
                flick.contentHeight *= 2
                flick.resizeContent(flick.contentWidth,
                                    flick.contentHeight,
                                    Qt.point(0,0))
//                 const mousePos = mapToItem(flick.contentItem, mouseX, mouseY)
//                 flick.contentItem.x = mousePos.x / 2
//                 flick.contentItem.y = mousePos.y / 2
//                 flick.returnToBounds()
            }
        }

        onWheel: {/*
                    var factor = 1 + wheel.angleDelta.y / 600;
                    zoomAnim.running = false;

                    zoomAnim.width = Math.min(Math.max(root.width, zoomAnim.width * factor), root.width * 4);
                    zoomAnim.height = Math.min(Math.max(root.height, zoomAnim.height * factor), root.height * 4);

                    //actual factors, may be less than factor
                    var xFactor = zoomAnim.width / flick.contentWidth;
                    var yFactor = zoomAnim.height / flick.contentHeight;
                } else if (wheel.pixelDelta.y != 0) {
                    flick.resizeContent(Math.min(Math.max(root.width, flick.contentWidth + wheel.pixelDelta.y), root.width * 4),
                                        Math.min(Math.max(root.height, flick.contentHeight + wheel.pixelDelta.y), root.height * 4),
                                        wheel);
                }
            } else {
                if (wheel.pixelDelta.y != 0) {
                    flick.contentX += wheel.pixelDelta.x;
                    flick.contentY += wheel.pixelDelta.y;
                } else {
                    flick.contentX -= wheel.angleDelta.x;
                    flick.contentY -= wheel.angleDelta.y;
                };*/
            if (wheel.modifiers & Qt.ControlModifier) {
                if (wheel.pixelDelta.y !== 0) {
                    flick.contentX += wheel.pixelDelta.x;
                    flick.contentY += wheel.pixelDelta.y;
                } else {
                    flick.contentX += angleDeltaToPixels(wheel.angleDelta.x)
                    flick.contentY += angleDeltaToPixels(wheel.angleDelta.y)
                }
            } else {
                const pixelDelta = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y
                    : angleDeltaToPixels(wheel.angleDelta.y)
                totalPixelDelta += pixelDelta

                const contentAspectRatio = flick.contentWidth / flick.contentHeight

                if (contentAspectRatio >= 1) {
                    flick.contentWidth = contentWidthForPixelDelta(wheel.pixelDelta.y)
                    flick.contentHeight = contentWidth / contentAspectRatio
                } else {
                    flick.contentHeight = contentHeightForPixelDelta(wheel.pixelDelta.y)
                    flick.contentWidth = contentHeight * (1 / contentAspectRatio)
                }

                flick.contentX = mouseX + flick.contentX
                flick.contentY = mouseY + flick.contentY
            }
        }
    }

    Controls.BusyIndicator {
        id: busyIndicator
        parent: flick
        anchors.centerIn: parent
        visible: running
        z: 1
        running: flick.videoPlayer ?
            flick.videoPlayer.status === MediaPlayer.Loading
            : flick.media && flick.media.status === Image.Loading
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
