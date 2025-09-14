/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 * SPDX-FileCopyrightText: (C) 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 * SPDX-FileCopyrightText: (C) 2021 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQml
import QtMultimedia
import org.kde.koko

BaseImageDelegate {
    id: root

    required property bool autoplay
    required property SlideshowManager slideShow

    loaded: player.mediaStatus === MediaPlayer.LoadedMedia
    loading: player.mediaStatus === MediaPlayer.LoadingMedia

    sourceWidth: player.implicitWidth
    sourceHeight: player.implicitHeight

    enabled: false

    data: VideoPlayer {
        id: player

        mainWindow: root.mainWindow
        anchors.fill: parent

        source: root.source

        onPlaybackStarted: {
            if (!root.isCurrent) {
                return;
            }
            // indicate that we're running a video
            if (root.slideShow.running) {
                root.slideShow.externalPlaybackStarted();
            }
        }
        onPlaybackFinished: {
            if (!root.isCurrent) {
                return;
            }
            // indicate that we stopped playing the video
            if (root.slideShow.externalMediaRunning) {
                root.slideShow.externalPlaybackFinished();
            }
        }
        // in case loader takes it's sweet time to load
        Component.onCompleted: {
            if (root.autoplay || (root.slideShow.running && root.isCurrent)) {
                play();
                root.autoplay = false;
            }
        }
    }

    onAutoplayChanged: {
        if (autoplay) { // play video automatically if started with "open with..."
            player.play();
            autoplay = false;
        }
    }

    onIsCurrentChanged: slideshowAutoplay()
    onSlideShowChanged: slideshowAutoplay()

    function slideshowAutoplay() {
        if (isCurrent && slideShow && slideShow.running) {
            player.play()
        } else {
            player.stop()
        }
    }

    Connections {
        target: root.slideShow
        function onRunningChanged() {
            // start playback if slideshow is running
            if (root.slideShow.running && root.isCurrent) {
                if (player.playing) { // indicate that video is already playing
                    root.slideShow.externalPlaybackStarted();
                } else {
                    player.play();
                }
            }
        }
    }

    Component.onDestruction: {
        // indicate playback being finished if delegate that started it was unloaded (i.e. by using thumbnail bar)
        if (slideShow.externalMediaRunning) {
            slideShow.externalPlaybackUnloaded()
        }
    }
}
