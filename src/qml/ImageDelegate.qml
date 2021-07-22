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
    readonly property real viewAspectRatio: root.width / root.height
    readonly property real mediaAspectRatio: root.mediaSourceWidth / root.mediaSourceHeight
    readonly property real widthZoomFactor: (videoPlayer ? contentItem.width : media.paintedWidth) / mediaSourceWidth
    readonly property real heightZoomFactor: (videoPlayer ? contentItem.height : media.paintedHeight) / mediaSourceHeight
    readonly property bool interactive: contentItem.width > root.width || contentItem.height > root.height
    readonly property bool dragging: mouseArea.drag.active || pinchArea.pinch.active

    // Returning sizes instead of separate widths and heights since they both need to be calculated together.

    function fittedContentSize(w, h) {
        const factor = root.mediaAspectRatio >= root.viewAspectRatio ? root.width / w : root.height / h
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
        const factor = root.mediaAspectRatio >= root.viewAspectRatio ? root.width / w : root.height / h
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
        property bool animationsEnabled: false
        property int animationDuration: Kirigami.Units.longDuration
        property int animationVelocity: 800
        implicitWidth: root.mediaSourceWidth
        implicitHeight: root.mediaSourceHeight
        width: root.defaultContentRect.width
        height: root.defaultContentRect.height
        x: root.defaultContentRect.x
        y: root.defaultContentRect.y
        //Behavior on width {
            //enabled: contentItem.animationsEnabled
            //SmoothedAnimation {
                //duration: contentItem.animationDuration
                //velocity: contentItem.animationVelocity
            //}
        //}
        //Behavior on height {
            //enabled: contentItem.animationsEnabled
            //SmoothedAnimation {
                //duration: contentItem.animationDuration
                //velocity: contentItem.animationVelocity
            //}
        //}
        //Behavior on x {
            //enabled: contentItem.animationsEnabled
            //SmoothedAnimation {
                //duration: contentItem.animationDuration
                //velocity: contentItem.animationVelocity
            //}
        //}
        //Behavior on y {
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
            target: contentItem; when: root.dragging
            property: "animationsEnabled"; value: false
            restoreMode: Binding.RestoreBindingOrValue
        }
    }

    Timer {
        id: doubleClickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval + 1
        onTriggered: applicationWindow().controlsVisible = !applicationWindow().controlsVisible
    }

//     DragHandler {
//         id: dragHandler
//     }
//     WheelHandler {
//         id: wheelHandler
//     }
    MouseArea {
        id: mouseArea
        property bool zoomDoubleClickToggled: false
        function angleDeltaToPixels(delta) {
            // 120 units == 1 step; (qreal) steps * line height * lines per step
            return delta / 120 * Kirigami.Units.gridUnit * Qt.styleHints.wheelScrollLines
        }
        anchors.fill: root
        enabled: !root.videoPlayer
        cursorShape: if (root.interactive) {
            return drag.active || pressed/* || root.listView.dragging*/ ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        } else {
            return Qt.ArrowCursor
        }
        drag {
            axis: Drag.XAndYAxis
            target: contentItem
            minimumX: root.width - contentItem.width
            maximumX: 0
            minimumY: root.height - contentItem.height
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
            if (root.interactive || zoomDoubleClickToggled) {
                zoomDoubleClickToggled = false
                contentItem.x = root.defaultContentRect.x
                contentItem.y = root.defaultContentRect.y
                contentItem.width = root.defaultContentRect.width
                contentItem.height = root.defaultContentRect.height
//                 root.resizeContent()
            } else {
                zoomDoubleClickToggled = true
                const newWidth = contentItem.width * 2
                const newHeight = contentItem.height * 2
                const mousePos = mapToItem(contentItem, mouse.x, mouse.y)
                contentItem.x = -mousePos.x - root.centerContentX(newWidth)
                contentItem.y = -mousePos.y - root.centerContentY(newHeight)
                contentItem.width = newWidth
                contentItem.height = newHeight
            }
        }
        onWheel: {
            zoomDoubleClickToggled = false
            contentItem.animationsEnabled = wheel.pixelDelta.x === 0 && wheel.pixelDelta.y === 0 && !(wheel.modifiers & Qt.ControlModifier || wheel.modifiers & Qt.ShiftModifier)

            const pixelDeltaY = wheel.pixelDelta.y !== 0 ?
                wheel.pixelDelta.y : angleDeltaToPixels(wheel.angleDelta.y)

            if (wheel.modifiers & Qt.ControlModifier || wheel.modifiers & Qt.ShiftModifier) {
                const pixelDeltaX = wheel.pixelDelta.x !== 0 ?
                    wheel.pixelDelta.x : angleDeltaToPixels(wheel.angleDelta.x)
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
                const mousePos = mapToItem(contentItem, wheel.x, wheel.y)
                if (root.mediaAspectRatio >= 1) {
                    const newWidth = root.boundedContentWidth(contentItem.width + pixelDeltaY * root.widthZoomFactor)
                    const newHeight = root.boundedContentHeight(newWidth / root.mediaAspectRatio)
                    const newX = root.boundedContentX(-mousePos.x, newWidth)
                    const newY = root.boundedContentY(-mousePos.y, newHeight)
                    console.log(
                        "old", contentItem.x, contentItem.y,
                        "new", newX, newY,
                        "wheel", wheel.x, wheel.y
                    )
                    contentItem.x = newX
                    contentItem.y = newY
                    contentItem.width = newWidth
                    contentItem.height = newHeight
                } else {
                    const newHeight = boundedContentHeight(contentItem.height + pixelDeltaY * root.heightZoomFactor)
                    const newWidth = boundedContentWidth(newHeight * (1 / root.mediaAspectRatio))
                    const newX = boundedContentX(-mousePos.x + root.centerContentX(newWidth), newWidth)
                    const newY = boundedContentY(-mousePos.y + root.centerContentY(newHeight), newHeight)
                    console.log("old", contentItem.x, contentItem.y,"new", newX, newY, "wheel", wheel)
                    contentItem.x = newX
                    contentItem.y = newY
                    contentItem.width = newWidth
                    contentItem.height = newHeight
                }
            }
        }
    }

    // TODO: test this with a device capable of generating pinch events
    PinchArea {
        id: pinchArea
        property real initialWidth: contentItem.width
        property real initialHeight: contentItem.height
        anchors.fill: root
        enabled: !root.videoPlayer
        pinch {
            dragAxis: Pinch.XAndYAxis
            target: contentItem
            minimumX: root.width - contentItem.width
            maximumX: 0
            minimumY: root.height - contentItem.height
            maximumY: 0
            minimumScale: 1
            maximumScale: 1
            minimumRotation: 0
            maximumRotation: 0
        }

        onPinchStarted: {
            mouseArea.zoomDoubleClickToggled = false
            initialWidth = contentItem.width
            initialHeight = contentItem.height
        }

        onPinchUpdated: {
            // adjust content pos due to drag
            //contentItem.x = pinch.previousCenter.x - pinch.center.x + contentItem.x
            //contentItem.y = pinch.previousCenter.y - pinch.center.y + contentItem.y

            // resize content
            contentItem.width = boundedContentWidth(initialWidth * pinch.scale)
            contentItem.height = boundedContentHeight(initialHeight * pinch.scale)
//             contentItem.x = boundedContentX(contentItem.x - pinch.center.x)
//             contentItem.y = boundedContentY(contentItem.y - pinch.center.y)
        }

        onPinchFinished: {
            // Move its content within bounds.
            if (contentItem.width < root.width
                || contentItem.height < root.height) {
                contentItem.x = root.centerContentX()
                contentItem.y = root.centerContentY()
            }
        }
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
