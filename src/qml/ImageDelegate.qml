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
    property alias contentX: contentItem.x // Can be NaN/undefined sometimes even when contentItem.x isn't.
    property alias contentY: contentItem.y // Can be NaN/undefined sometimes even when contentItem.y isn't.
    property alias contentWidth: contentItem.width
    property alias contentHeight: contentItem.height
    readonly property rect defaultContentRect: {
        const size = fittedContentSize(root.mediaSourceWidth, root.mediaSourceHeight)
        return Qt.rect(centerContentX(size.width), centerContentY(size.height), size.width, size.height)
    }
    readonly property real rootAspectRatio: root.width / root.height
    readonly property real mediaAspectRatio: root.mediaSourceWidth / root.mediaSourceHeight
    readonly property real widthZoomFactor: (videoPlayer ? contentItem.width : media.paintedWidth) / mediaSourceWidth
    readonly property real heightZoomFactor: (videoPlayer ? contentItem.height : media.paintedHeight) / mediaSourceHeight
    readonly property bool interactive: Math.floor(contentItem.width) > root.width || Math.floor(contentItem.height) > root.height
    property MouseArea mouseArea: null
    property PinchArea pinchArea: null
    property bool dragging: mouseArea && pinchArea && (mouseArea.drag.active || pinchArea.pinch.active)
    property bool animationsEnabled: false
    property int animationDuration: Kirigami.Units.longDuration
    property int animationVelocity: 800

    // Returning sizes instead of separate widths and heights since they both need to be calculated together.

    // Fit to root
    function fittedContentSize(w, h) {
        const factor = root.mediaAspectRatio >= root.rootAspectRatio ? root.width / w : root.height / h
        if (w > root.width || h > root.height) {
            w = w * factor
            h = h * factor
        }
        return Qt.size(w, h)//new RectF(newLeft, newTop, newWidth + newLeft, newHeight + newTop)
    }

    function defaultContentSize() {
        return fittedContentSize(root.mediaSourceWidth, root.mediaSourceHeight)
    }

    function centerContentX(cWidth = contentItem.width) {
        return (root.width - cWidth) / 2
    }

    function centerContentY(cHeight = contentItem.height) {
        return (root.height - cHeight) / 2
    }

    function bound(min, value, max) {
        return Math.min(Math.max(min, value), max)
    }

    function boundedContentSize(w, h) {
        w = bound(root.defaultContentRect.width, w, mediaSourceWidth * 16)
        h = bound(root.defaultContentRect.height, h, mediaSourceHeight * 16)
        const factor = root.mediaAspectRatio >= root.rootAspectRatio ? root.width / w : root.height / h
        if (w > root.width || h > root.height) {
            w = w * factor
            h = h * factor
        }
        return Qt.size(w,h)
    }

    function boundedContentWidth(newWidth) {
        // sourceSize * 16 is arbitrary. Gwenview used 16 as its max zoom factor.
        return bound(root.defaultContentRect.width, newWidth, mediaSourceWidth * 16)
    }

    function boundedContentHeight(newHeight) {
        // sourceSize * 16 is arbitrary. Gwenview used 16 as its max zoom factor.
        return bound(root.defaultContentRect.height, newHeight, mediaSourceHeight * 16)
    }

    function boundedContentX(newX, cWidth = contentItem.width) {
        return bound(root.width - cWidth, newX, 0)
    }

    function boundedContentY(newY, cHeight = contentItem.height) {
        return bound(root.height - cHeight, newY, 0)
    }

    clip: true

    Item {
        id: contentItem
        implicitWidth: root.mediaSourceWidth
        implicitHeight: root.mediaSourceHeight
        width: root.defaultContentRect.width
        height: root.defaultContentRect.height
        x: root.defaultContentRect.x
        y: root.defaultContentRect.y
    }

    //Behavior on contentItem.width {
        //enabled: contentItem.animationsEnabled
        //SmoothedAnimation {
            //duration: contentItem.animationDuration
            //velocity: contentItem.animationVelocity
        //}
    //}
    //Behavior on contentItem.height {
        //enabled: contentItem.animationsEnabled
        //SmoothedAnimation {
            //duration: contentItem.animationDuration
            //velocity: contentItem.animationVelocity
        //}
    //}
    //Behavior on contentItem.x {
        //enabled: contentItem.animationsEnabled
        //SmoothedAnimation {
            //duration: contentItem.animationDuration
            //velocity: contentItem.animationVelocity
        //}
    //}
    //Behavior on contentItem.y {
        //enabled: contentItem.animationsEnabled
        //SmoothedAnimation {
            //duration: contentItem.animationDuration
            //velocity: contentItem.animationVelocity
        //}
    //}

    //Binding {
        //target: contentItem; when: root.mediaAspectRatio < 1
        //property: "width"; value: contentItem.height * (1 / root.mediaAspectRatio)
        //restoreMode: Binding.RestoreNone
    //}
    //Binding {
        //target: contentItem; when: root.mediaAspectRatio >= 1
        //property: "height"; value: contentItem.width / root.mediaAspectRatio
        //restoreMode: Binding.RestoreNone
    //}
    Binding {
        target: contentItem; when: contentItem.width <= root.width && !root.dragging
        property: "x"; value: (root.width - contentItem.width) / 2
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: contentItem; when: contentItem.height <= root.height && !root.dragging
        property: "y"; value: (root.height - contentItem.height) / 2
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root; when: root.dragging
        property: "animationsEnabled"; value: false
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
            smooth: false
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
            smooth: false
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
    
    onInteractiveChanged: console.debug("root", root.width, root.height, "contentItem", contentItem.width, contentItem.height)

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
