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

MouseArea {
    id: root
    property string currentImageSource
    property string currentImageMimeType
    property ListView listView: ListView.view
    property bool autoplay: false // Enable autoplay for video.
    property bool isCurrentImage: ListView.isCurrentItem
    readonly property bool interactive: Math.floor(contentItem.width) > root.width || Math.floor(contentItem.height) > root.height
    property bool dragging: root.drag.active || pinchArea.pinch.active

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

    property real mediaSourceWidth: videoPlayer ? videoPlayer.implicitWidth : media.sourceSize.width
    property real mediaSourceHeight: videoPlayer ? videoPlayer.implicitHeight : media.sourceSize.height
    readonly property real mediaAspectRatio: root.mediaSourceWidth / root.mediaSourceHeight

    /**
     * Properties used for contentItem manipulation.
     */
    readonly property alias contentItem: contentItem
    // NOTE: Unlike Flickable, contentX and contentY do not have reversed signs.
    // NOTE: contentX and contentY can be NaN/undefined sometimes even when
    // contentItem.x and contentItem.y aren't and I'm not sure why.
    property alias contentX: contentItem.x
    property alias contentY: contentItem.y
    property alias contentWidth: contentItem.width
    property alias contentHeight: contentItem.height
    readonly property rect defaultContentRect: {
        const size = fittedContentSize(root.mediaSourceWidth, root.mediaSourceHeight)
        return Qt.rect(centerContentX(size.width), centerContentY(size.height), size.width, size.height)
    }
    readonly property real viewAspectRatio: root.width / root.height
    // Should be the same for both width and height
    readonly property real zoomFactor: (videoPlayer || vectorImage ? contentItem.width : media.paintedWidth) / mediaSourceWidth

    // Fit to root unless arguments are smaller than the size of root.
    // Returning size instead of using separate width and height functions
    // since they both need to be calculated together.
    function fittedContentSize(w, h) {
        const factor = root.mediaAspectRatio >= root.viewAspectRatio ? root.width / w : root.height / h
        if (w > root.width || h > root.height) {
            w = w * factor
            h = h * factor
        }
        return Qt.size(w, h)
    }

    // Get the X value that would center the contentItem with the given content width.
    function centerContentX(cWidth = contentItem.width) {
        return Math.round((root.width - cWidth) / 2)
    }

    // Get the Y value that would center the contentItem with the given content height.
    function centerContentY(cHeight = contentItem.height) {
        return Math.round((root.height - cHeight) / 2)
    }

    // Right side of media touches right side of root.
    function minContentX(cWidth = contentItem.width) {
        return cWidth > root.width ? root.width - cWidth : centerContentX(cWidth)
    }
    // Left side of media touches left side of root.
    function maxContentX(cWidth = contentItem.width) {
        return cWidth > root.width ? 0 : centerContentX(cWidth)
    }
    // Bottom side of media touches bottom side of root.
    function minContentY(cHeight = contentItem.height) {
        return cHeight > root.height ? root.height - cHeight : centerContentY(cHeight)
    }
    // Top side of media touches top side of root.
    function maxContentY(cHeight = contentItem.height) {
        return cHeight > root.height ? 0 : centerContentY(cHeight)
    }

    function bound(min, value, max) {
        return Math.min(Math.max(min, value), max)
    }

    /**
     * Using very small min sizes and very large max sizes since there don't seem
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
    function boundedContentWidth(newWidth) {
        return bound(Math.min(mediaSourceWidth, 8), newWidth, mediaSourceWidth * 100)
    }
    function boundedContentHeight(newHeight) {
        return bound(Math.min(mediaSourceHeight, 8), newHeight, mediaSourceHeight * 100)
    }

    function boundedContentX(newX, cWidth = contentItem.width) {
        return Math.round(bound(minContentX(cWidth), newX, maxContentX(cWidth)))
    }
    function boundedContentY(newY, cHeight = contentItem.height) {
        return Math.round(bound(minContentY(cHeight), newY, maxContentY(cHeight)))
    }

    function heightForWidth(w = contentItem.width) {
        return w / root.mediaAspectRatio
    }
    function widthForHeight(h = contentItem.height) {
        return h * root.mediaAspectRatio
    }

    function addContentSize(value, w = contentItem.width, h = contentItem.height) {
        if (root.mediaAspectRatio >= 1) {
            w = boundedContentWidth(w + value)
            h = heightForWidth(w)
        } else {
            h = boundedContentHeight(h + value)
            w = widthForHeight(h)
        }
        return Qt.size(w, h)
    }

    function multiplyContentSize(value, w = contentItem.width, h = contentItem.height) {
        if (root.mediaAspectRatio >= 1) {
            w = boundedContentWidth(w * value)
            h = heightForWidth(w)
        } else {
            h = boundedContentHeight(h * value)
            w = widthForHeight(h)
        }
        return Qt.size(w, h)
    }

    /**
     * Basic formula: (qreal) steps * singleStep * wheelScrollLines
     * 120 delta units == 1 step.
     * singleStep is the step amount in pixels.
     * wheelScrollLines is the step multiplier.
     *
     * There is no real standard for scroll speed.
     * - QScrollArea uses `singleStep = 20`
     * - QGraphicsView uses `singleStep = dimension / 20`
     * - Kirigami WheelHandler uses `singleStep = delta / 8`
     * - Some apps use `singleStep = QFontMetrics::height()`
     */
    function angleDeltaToPixels(delta, dimension) {
        const singleStep = dimension !== undefined ? dimension / 20 : 20
        return delta / 120 * singleStep * Qt.styleHints.wheelScrollLines
    }

    clip: true
    enabled: !root.videoPlayer
    acceptedButtons: root.interactive ? Qt.LeftButton | Qt.MiddleButton : Qt.LeftButton
    cursorShape: if (root.interactive) {
        return pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    } else {
        return Qt.ArrowCursor
    }

    drag {
        axis: Drag.XAndYAxis
        target: root.interactive ? contentItem : undefined
        minimumX: root.minContentX(contentItem.width)
        maximumX: root.maxContentX(contentItem.width)
        minimumY: root.minContentY(contentItem.height)
        maximumY: root.maxContentY(contentItem.height)
    }

    Item {
        id: contentItem
        implicitWidth: root.mediaSourceWidth
        implicitHeight: root.mediaSourceHeight
        width: root.defaultContentRect.width
        height: root.defaultContentRect.height
        x: root.defaultContentRect.x
        y: root.defaultContentRect.y
    }

    // Auto center
    Binding {
        // we tried using delayed here but that causes flicker issues
        target: contentItem; property: "x"
        when: root.loaded && Math.floor(contentItem.width) <= root.width && !root.dragging
        value: root.centerContentX(contentItem.width)
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: contentItem; property: "y"
        when: root.loaded && Math.floor(contentItem.height) <= root.height && !root.dragging
        value: root.centerContentY(contentItem.height)
        restoreMode: Binding.RestoreNone
    }

    onWidthChanged: if (contentItem.width > width) {
        contentItem.x = boundedContentX(contentItem.x)
    }
    onHeightChanged: if (contentItem.height > height) {
        contentItem.y = boundedContentY(contentItem.y)
    }

    // TODO: test this with a device capable of generating pinch events
    PinchArea {
        id: pinchArea
        property real initialWidth: 0
        property real initialHeight: 0
        anchors.fill: root
        enabled: root.enabled
        pinch {
            dragAxis: Pinch.XAndYAxis
            target: root.drag.target
            minimumX: root.drag.minimumX
            maximumX: root.drag.maximumX
            minimumY: root.drag.minimumY
            maximumY: root.drag.maximumY
            minimumScale: 1
            maximumScale: 1
            minimumRotation: 0
            maximumRotation: 0
        }

        onPinchStarted: {
            initialWidth = contentItem.width
            initialHeight = contentItem.height
        }

        onPinchUpdated: {
            // adjust content pos due to drag
            //contentItem.x = pinch.previousCenter.x - pinch.center.x + contentItem.x
            //contentItem.y = pinch.previousCenter.y - pinch.center.y + contentItem.y

            // resize content
            const newSize = root.multiplyContentSize(pinch.scale, initialWidth, initialHeight)
            contentItem.width = newSize.width
            contentItem.height = newSize.height
            //contentItem.x = boundedContentX(contentItem.x - pinch.center.x)
            //contentItem.y = boundedContentY(contentItem.y - pinch.center.y)
        }
    }

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
        if (Kirigami.Settings.isMobile) { applicationWindow().controlsVisible = false }
        if (contentItem.width !== root.defaultContentRect.width || contentItem.height !== root.defaultContentRect.height) {
            contentItem.width = Qt.binding(() => root.defaultContentRect.width)
            contentItem.height = Qt.binding(() => root.defaultContentRect.height)
        } else {
            const cX = contentItem.x, cY = contentItem.y
            contentItem.width = root.defaultContentRect.width * 2
            contentItem.height = root.defaultContentRect.height * 2
            // content position * factor - mouse position
            contentItem.x = root.boundedContentX(cX * 2 - mouse.x, contentItem.width)
            contentItem.y = root.boundedContentY(cY * 2 - mouse.y, contentItem.height)
        }
    }
    onWheel: {

        if (wheel.modifiers & Qt.ControlModifier || wheel.modifiers & Qt.ShiftModifier) {
            const pixelDeltaX = wheel.pixelDelta.x !== 0 ?
                wheel.pixelDelta.x : angleDeltaToPixels(wheel.angleDelta.x, root.width)
            const pixelDeltaY = wheel.pixelDelta.y !== 0 ?
                wheel.pixelDelta.y : angleDeltaToPixels(wheel.angleDelta.y, root.height)
            if (pixelDeltaX !== 0 && pixelDeltaY !== 0) {
                contentItem.x = root.boundedContentX(pixelDeltaX + contentItem.x)
                contentItem.y = root.boundedContentY(pixelDeltaY + contentItem.y)
            } else if (pixelDeltaX !== 0 && pixelDeltaY === 0) {
                contentItem.x = root.boundedContentX(pixelDeltaX + contentItem.x)
            } else if (pixelDeltaX === 0 && pixelDeltaY !== 0 && wheel.modifiers & Qt.ShiftModifier) {
                contentItem.x = root.boundedContentX(pixelDeltaY + contentItem.x)
            } else {
                contentItem.y = root.boundedContentY(pixelDeltaY + contentItem.y)
            }
        } else {
            let factor = 1 + Math.abs(wheel.angleDelta.y / 600)
            if (wheel.angleDelta.y < 0) {
                factor = 1 / factor
            }
            const oldRect = Qt.rect(contentItem.x, contentItem.y, contentItem.width, contentItem.height)
            const newSize = root.multiplyContentSize(factor)
            // round to default size if within ±1
            if ((newSize.height > root.defaultContentRect.height - 1
                && newSize.height < root.defaultContentRect.height + 1)
             || (newSize.width > root.defaultContentRect.width - 1
                && newSize.width < root.defaultContentRect.width + 1)
            ) {
                contentItem.width = root.defaultContentRect.width
                contentItem.height = root.defaultContentRect.height
            } else {
                contentItem.width = newSize.width
                contentItem.height = newSize.height
            }
            if (root.interactive) {
                contentItem.x = root.boundedContentX(wheel.x - contentItem.width * ((wheel.x - oldRect.x)/oldRect.width))
                contentItem.y = root.boundedContentY(wheel.y - contentItem.height * ((wheel.y - oldRect.y)/oldRect.height))
            }
        }
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
            anchors.fill: contentItem
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
            anchors.fill: contentItem
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
        animatedImage = animatedImageComponent.createObject(contentItem)
        image = null
    } else if (image === null) {
        videoPlayer = null
        vectorImage = null
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
        contentItem.width = Qt.binding(() => root.defaultContentRect.width)
        contentItem.height = Qt.binding(() => root.defaultContentRect.height)
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
