/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: (C) 2021 Noah Davis <noahadvs@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15
import QtMultimedia 5.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1
import org.kde.koko.image 0.1

ZoomArea {
    id: root
    property string currentImageSource
    property string currentImageMimeType
    property ListView listView: ListView.view
    property bool autoplay: false // Enable autoplay for video.
    property bool isCurrentImage: ListView.isCurrentItem

    /**
     * Used to contain the current media viewer with the option
     * to check for a specific type of media viewer or not.
     */
    property VideoPlayer videoPlayer: null
    property VectorImage vectorImage: null
    property AnimatedImage animatedImage: null
    property Image image: null
    readonly property Item media: videoPlayer || vectorImage || animatedImage || image

    /**
     * Properties for info about the media and media viewer.
     */
    readonly property int status: media ? media.status : 0 // 0 is equal to MediaPlayer.UnknownStatus and Image.Null
    readonly property bool loaded: videoPlayer ? status === MediaPlayer.Loaded
                                               : vectorImage ? media.status === VectorImage.Ready
                                               : media.status === Image.Ready

    readonly property bool loading: videoPlayer ? status === MediaPlayer.Loading
                                                : vectorImage ? media.status === VectorImage.Loading
                                                : media.status === Image.Loading

    implicitContentWidth: videoPlayer ? videoPlayer.implicitWidth : media.sourceSize.width
    implicitContentHeight: videoPlayer ? videoPlayer.implicitHeight : media.sourceSize.height

    /* Using very small min sizes and very large max sizes since there don't seem
     * to be many good reasons to use more limited ranges.
     *
     * The best tools are simple, but allow users to do complex things without
     * needing to add more complexity.
     * Maybe an artist wants to view the pixels of an image up close to see the
     * exact colors better or shrink an image to see the average colors.
     * We could require the artist to use something like ImageMagick to do that,
     * or we could let them use their favorite image viewer and a color picker to
     * do the same job without having to learn ImageMagick.
     *
     * 8 was picked as the minimum size unless the source size is smaller.
     * It's a fairly arbitrary number. Maybe it could be 1, but that's really
     * really difficult to see and sometimes the single pixel is impossible to see.
     *
     * Media source size times 100 was picked for the max size because that
     * allows Koko to show roughly 19x10 pixels at once when full screen on a
     * 1920x1080 screen at max zoom. An arbitrary number, but it should be fine.
     * QQuickImage is very good at handling large sizes, so unlike Gwenview,
     * performance isn't much of a concern when picking the max size.
     */
    minimumZoomSize: 8
    maximumZoomFactor: 100

    enabled: !root.videoPlayer

    Timer {
        id: doubleClickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval + 1
        onTriggered: applicationWindow().controlsVisible = !applicationWindow().controlsVisible
    }
    onClicked: if (mouse.button === Qt.LeftButton) {
        contextDrawer.drawerOpen = false
        doubleClickTimer.restart()
    }
    onDoubleClicked: if (mouse.button === Qt.LeftButton) {
        doubleClickTimer.stop()
    }

    Component {
        id: videoPlayerComponent
        VideoPlayer {
            anchors.fill: root
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
        id: vectorImageComponent
        VectorImage {
            anchors.fill: root
            source: currentImageSource
            sourceClipRect: Qt.rect(-root.contentX, -root.contentY, root.contentWidth, root.contentHeight)
        }
    }

    Component {
        id: animatedImageComponent
        // sadly sourceSize is read only in AnimatedImage, so we keep it separate
        AnimatedImage {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: currentImageSource
            smooth: root.zoomFactor < 1
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
            smooth: root.zoomFactor < 1
            autoTransform: true
            asynchronous: true
            colorSpace: DisplayColorSpace.colorSpace
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
        videoPlayer = videoPlayerComponent.createObject(root)
        vectorImage = null
        animatedImage = null
        image = null
    } else if ((currentImageSource.endsWith(".svg") || currentImageSource.endsWith(".svgz")) && vectorImage === null) {
        videoPlayer = null
        vectorImage = vectorImageComponent.createObject(root)
        animatedImage = null
        image = null
    } else if (currentImageSource.endsWith(".gif") && animatedImage === null) {
        videoPlayer = null
        vectorImage = null
        animatedImage = animatedImageComponent.createObject(root.contentItem)
        image = null
    } else if (image === null) {
        videoPlayer = null
        vectorImage = null
        animatedImage = null
        image = imageComponent.createObject(root.contentItem)
    }

    onAutoplayChanged: {
        if (autoplay && videoPlayer) { // play video automatically if started with "open with..."
            videoPlayer.play();
            autoplay = false;
        }
    }

    onIsCurrentImageChanged: {
        root.contentWidth = Qt.binding(() => root.defaultContentRect.width)
        root.contentHeight = Qt.binding(() => root.defaultContentRect.height)
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
