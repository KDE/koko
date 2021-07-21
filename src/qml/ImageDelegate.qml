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
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1

Item {
    id: root
    property string currentImageSource
    property string currentImageMimeType
    property ListView listView
    property bool autoplay: false
    property bool isCurrentImage: ListView.isCurrentItem
    property VideoPlayer videoPlayer: null
    property AnimatedImage animatedImage: null
    property Image image: null
    readonly property Item media: videoPlayer || animatedImage || image
    readonly property int status: media ? media.status : 0
    // get info from Exiv2Extractor if not video
    property real mediaSourceWidth: 0
    property real mediaSourceHeight: 0
    readonly property alias contentItem: contentItem
    property alias contentX: contentItem.x
    property alias contentY: contentItem.y
    property alias contentWidth: contentItem.width
    property alias contentHeight: contentItem.height
    readonly property real zoomFactor: root.contentWidth / mediaSourceWidth
    readonly property bool interactive: root.contentWidth > root.width || root.contentHeight > root.height
    readonly property alias dragging: mouseArea.drag.active

    function defaultContentWidth() {
        return Math.min(root.mediaSourceWidth, root.width)
    }

    function defaultContentHeight() {
        return Math.min(root.mediaSourceHeight, root.height)
    }

    function centerContentX(cWidth = root.contentWidth) {
        return (root.width - root.contentWidth) / 2
    }

    function centerContentY(cHeight = root.contentHeight) {
        return (root.height - root.contentHeight) / 2
    }

    function bound(min, value, max) {
        return Math.min(Math.max(min, value), max)
    }

    function boundedContentWidth(newWidth) {
        return bound(root.defaultContentWidth(), newWidth, mediaSourceWidth * 16)
    }

    function boundedContentHeight(newHeight) {
        return bound(root.defaultContentHeight(), newHeight, mediaSourceHeight * 16)
    }

    function boundedContentX(newX, cWidth = root.contentWidth) {
        return bound(root.width - cWidth, newX, 0)
    }

    function boundedContentY(newY, cHeight = root.contentHeight) {
        return bound(root.height - cHeight, newY, 0)
    }

    function resizeContent(
        newWidth = Math.min(root.mediaSourceWidth, root.width),
        newHeight = Math.min(root.mediaSourceHeight, root.height),
        newX = (root.width - newWidth) / 2,
        newY = (root.height - newHeight) / 2
    ) {
        //root.contentX + (centerX * newWidth / root.contentWidth) - centerX
        //root.contentY + (centerY * newHeight / root.contentHeight) - centerY
        root.contentWidth = newWidth
        root.contentHeight = newHeight
        root.contentX = newX
        root.contentY = newY
    }

    clip: true

    Item {
        id: contentItem
        property bool animationsEnabled: false
        property int animationDuration: Kirigami.Units.longDuration
        property int animationVelocity: 800
        implicitWidth: root.mediaSourceWidth
        implicitHeight: root.mediaSourceHeight
        width: root.defaultContentWidth()
        height: root.defaultContentHeight()
        x: root.centerContentX()
        y: root.centerContentY()
        Behavior on width {
            enabled: contentItem.animationsEnabled
            SmoothedAnimation {
                duration: contentItem.animationDuration
                velocity: contentItem.animationVelocity
            }
        }
        Behavior on height {
            enabled: contentItem.animationsEnabled
            SmoothedAnimation {
                duration: contentItem.animationDuration
                velocity: contentItem.animationVelocity
            }
        }
        Behavior on x {
            enabled: contentItem.animationsEnabled
            SmoothedAnimation {
                duration: contentItem.animationDuration
                velocity: contentItem.animationVelocity
            }
        }
        Behavior on y {
            enabled: contentItem.animationsEnabled
            SmoothedAnimation {
                duration: contentItem.animationDuration
                velocity: contentItem.animationVelocity
            }
        }
    }

    //Binding {
        //target: root; when: contentWidth <= width
        //property: "contentX"; value: (root.width - root.contentWidth) / 2
        //restoreMode: Binding.RestoreBinding
    //}
    //Binding {
        //target: root; when: contentHeight <= height
        //property: "contentY"; value: (root.height - root.contentHeight) / 2
        //restoreMode: Binding.RestoreBinding
    //}

    PinchArea {
        id: pinchArea
        anchors.fill: root
        enabled: !root.videoPlayer
        //x: root.contentWidth > root.width ? root.contentX : 0
        //y: root.contentHeight > root.height ? root.contentY : 0
        //width: Math.max(root.contentWidth, root.width)
        //height: Math.max(root.contentHeight, root.height)

        property real initialWidth
        property real initialHeight
        onPinchStarted: {
            initialWidth = root.contentWidth
            initialHeight = root.contentHeight
        }

        onPinchUpdated: {
            contentItem.animationsEnabled = false
            // adjust content pos due to drag
            root.contentX = pinch.previousCenter.x - pinch.center.x + root.contentX
            root.contentY = pinch.previousCenter.y - pinch.center.y + root.contentY

            // resize content
            root.contentWidth = Math.max(root.width*0.7, initialWidth * pinch.scale)
            root.contentHeight = Math.max(root.height*0.7, initialHeight * pinch.scale)
            root.contentX = pinch.center.x + root.contentX
            root.contentY = pinch.center.y + root.contentY
        }

        onPinchFinished: {
            contentItem.animationsEnabled = false
            // Move its content within bounds.
            if (root.contentWidth < root.width
                || root.contentHeight < root.height) {
                if (root.contentWidth < root.mediaSourceWidth
                    || root.contentHeight < root.mediaSourceHeight) {
                    root.contentWidth = mediaSourceWidth
                    root.contentHeight = mediaSourceHeight
                }
                root.contentX = root.centerContentX()
                root.contentY = root.centerContentY()
            }/* else {
                flick.returnToBounds();
            }*/
        }
    }

    Timer {
        id: doubleClickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval + 1
        onTriggered: applicationWindow().controlsVisible = !applicationWindow().controlsVisible
    }

    MouseArea {
        id: mouseArea
        function angleDeltaToPixels(delta) {
            // 120 units == 1 step; steps * line height * lines per step
            return delta / 120 * Kirigami.Units.gridUnit * Qt.styleHints.wheelScrollLines
        }
        anchors.fill: root
        enabled: !root.videoPlayer
        cursorShape: if (drag.target) {
            return drag.active/* || root.listView.dragging*/ ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        } else {
            return undefined
        }
        drag {
            axis: Drag.XAndYAxis
            target: contentItem
            minimumX: root.width - root.contentWidth
            maximumX: 0
            minimumY: root.height - root.contentHeight
            maximumY: 0
        }
        onClicked: {
            contextDrawer.drawerOpen = false
            doubleClickTimer.restart()
        }
        onDoubleClicked: {
            doubleClickTimer.stop()
            if (Kirigami.Settings.isMobile) { applicationWindow().controlsVisible = false }
            contentItem.animationsEnabled = true
            if (root.interactive) {
                root.resizeContent()
                //contentWidth: Qt.binding(root.defaultContentWidth)
                //contentHeight: Qt.binding(root.defaultContentHeight)
            } else {
                const newWidth = root.contentWidth * 2
                const newHeight = root.contentHeight * 2
                root.resizeContent(newWidth,
                                   newHeight,
                                   root.contentX - mouseX - root.centerContentX(newWidth),
                                   root.contentY - mouseY - root.centerContentY(newHeight))
            }
        }
        onWheel: {
            contentItem.animationsEnabled = wheel.pixelDelta.x === 0 && wheel.pixelDelta.y === 0

            const pixelDeltaY = wheel.pixelDelta.y !== 0 ?
                wheel.pixelDelta.y : angleDeltaToPixels(wheel.angleDelta.y)

            if (wheel.modifiers & Qt.ControlModifier || wheel.modifiers & Qt.ShiftModifier) {
                const pixelDeltaX = wheel.pixelDelta.x !== 0 ?
                    wheel.pixelDelta.x : angleDeltaToPixels(wheel.angleDelta.x)
                if (pixelDeltaX !== 0 && pixelDeltaY !== 0) {
                    root.contentX = root.bound(root.width - root.contentWidth,
                                               pixelDeltaX + root.contentX,
                                               0)
                    root.contentY = root.bound(root.height - root.contentHeight,
                                               pixelDeltaY + root.contentY,
                                               0)
                } else if (pixelDeltaX !== 0 && pixelDeltaY === 0) {
                    root.contentX = root.bound(root.width - root.contentWidth,
                                               pixelDeltaX + root.contentX,
                                               0)
                } else if (pixelDeltaX === 0 && pixelDeltaY !== 0 && wheel.modifiers & Qt.ShiftModifier) {
                    root.contentX = root.bound(root.width - root.contentWidth,
                                               pixelDeltaY + root.contentX,
                                               0)
                } else {
                    root.contentY = root.bound(root.height - root.contentHeight,
                                               pixelDeltaY + root.contentY,
                                               0)
                }
            } else {
                const pixelDelta = pixelDeltaY * root.zoomFactor
                const contentAspectRatio = root.contentWidth / root.contentHeight
                if (contentAspectRatio >= 1) {
                    const newWidth = boundedContentWidth(root.contentWidth + pixelDelta)
                    const newHeight = boundedContentHeight(newWidth / contentAspectRatio)
                    const newX = boundedContentX(root.centerContentX(newWidth) - mouseX + root.contenX)
                    const newY = boundedContentY(root.centerContentY(newHeight) - mouseY + root.contenY)
                    root.resizeContent(newWidth, newHeight, newX, newY)
                } else {
                    const newHeight = boundedContentHeight(root.contentHeight + pixelDelta)
                    const newWidth = boundedContentWidth(newHeight * (1 / contentAspectRatio))
                    const newX = boundedContentX(root.centerContentX(newWidth) - mouseX + root.contenX)
                    const newY = boundedContentY(root.centerContentY(newHeight) - mouseY + root.contenY)
                    root.resizeContent(newWidth, newHeight, newX, newY)
                }
            }
        }
    }

    Binding {
        target: contentItem; when: root.dragging
        property: "animationsEnabled"; value: !root.dragging
        restoreMode: Binding.RestoreBindingOrValue
    }

    Component {
        id: videoPlayerComponent
        VideoPlayer {
            anchors.fill: parent
            source: currentImageSource
            onPlaybackStarted: {
                if (!root.isCurrentImage) {
                    return;
                }
                // indicate that we're running a video
                if (listView.slideshow.running) {
                    listView.slideshow.externalPlaybackStarted();
                }
            }
            onPlaybackFinished: {
                if (!root.isCurrentImage) {
                    return;
                }
                // indicate that we stopped playing the video
                if (listView.slideshow.externalMediaRunning) {
                    listView.slideshow.externalPlaybackFinished();
                }
            }
            // in case loader takes it's sweet time to load
            Component.onCompleted: if (root.autoplay
                || (listView.slideshow.running && root.isCurrentImage)) {
                play();
                root.autoplay = false;
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

    onCurrentImageMimeTypeChanged: if (
        currentImageMimeType.startsWith("video/") && videoPlayer === null
    ) {
        videoPlayer = videoPlayerComponent.createObject(contentItem)
        animatedImage = null
        image = null
    } else if (currentImageSource.endsWith(".gif") && animatedImage === null) {
        videoPlayer = null
        animatedImage = animatedImageComponent.createObject(contentItem)
        image = null
    } else if (image === null) {
        videoPlayer = null
        animatedImage = null
        image = imageComponent.createObject(contentItem)
    }

    onAutoplayChanged: {
        if (autoplay && videoPlayer) { // play video automatically if started with "open with..."
            videoPlayer.play();
            autoplay = false;
        }
    }

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

    Connections {
        target: listView.slideshow
        function onRunningChanged() {
            // start playback if slideshow is running
            if (listView.slideshow.running && root.isCurrentImage && videoPlayer) {
                if (videoPlayer.playing) { // indicate that video is already playing
                    listView.slideshow.externalPlaybackStarted();
                } else {
                    videoPlayer.play();
                }
            }
        }
    }
}
