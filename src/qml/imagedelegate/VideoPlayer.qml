/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import QtMultimedia
import org.kde.coreaddons as KCA

Item {
    id: videoPlayerRoot

    required property Kirigami.ApplicationWindow mainWindow

    // `required` here breaks stuff
    property string source
    readonly property alias player: videoPlayer
    readonly property bool playing: videoPlayer.playbackState === MediaPlayer.PlayingState
    readonly property alias mediaStatus: videoPlayer.mediaStatus

    // signals when playback starts and finishes
    signal playbackStarted()
    signal playbackFinished()

    // convenience function
    function play(): void {
        if (videoPlayer.status != MediaPlayer.Loaded) {
            videoPlayer.autoPlay = true
        } else {
            videoPlayer.play();
        }
    }

    function stop(): void {
        videoPlayer.stop();
    }

    implicitWidth: videoOutput.implicitWidth
    implicitHeight: videoOutput.implicitHeight

    Timer {
        id: doubleClickTimer
        interval: 150
        onTriggered: {
            root.mainWindow.controlsVisible = !root.mainWindow.controlsVisible;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.mainWindow.contextDrawer) {
                root.mainWindow.contextDrawer.drawerOpen = false;
            }
            doubleClickTimer.restart();
        }
        onDoubleClicked: {
            doubleClickTimer.running = false;
            if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                videoPlayer.pause();
            } else{
                videoPlayer.play();
            }
        }
    }

    MediaPlayer {
        id: videoPlayer

        source: videoPlayerRoot.source

        onPlaybackStateChanged: if (playbackState === MediaPlayer.StoppedState) {
            videoPlayerRoot.playbackFinished();
        } else if (playbackState === MediaPlayer.PlayingState) {
            videoPlayerRoot.playbackStarted();
        }

        audioOutput: AudioOutput {
            id: audioOutput
            volume: volumeSlider.value
        }

        videoOutput: videoOutput

        loops: videoPlayer.duration >= 5000 ? 1 : MediaPlayer.Infinite // loop short videos

        function seekForward(): void {
            if (!videoPlayer.seekable) {
                return;
            }

            if (videoPlayer.position + 5000 < videoPlayer.duration) {
                videoPlayer.position =+ 5000;
            } else {
                videoPlayer.position = 0;
                videoPlayer.stop();
            }
        }

        function seekBackward(): void {
            if (!videoPlayer.seekable) {
                return;
            }

            videoPlayer.position -= 5000;
        }
    }

    VideoOutput {
        id: videoOutput

        implicitWidth: videoPlayer.metaData.resolution ? videoPlayer.metaData.resolution.width : 0
        implicitHeight: videoPlayer.metaData.resolution ? videoPlayer.metaData.resolution.height : 0

        anchors.fill: parent
    }

    Controls.ToolButton {
        anchors.centerIn: parent

        icon.name: "media-playback-start"
        icon.color: "white"

        icon.width: Kirigami.Units.gridUnit * 3
        icon.height: Kirigami.Units.gridUnit * 3

        visible: videoPlayer.playbackState === MediaPlayer.StoppedState

        onClicked: {
            videoPlayer.play();
        }
    }

    Item {
        id: playerToolbar

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: Kirigami.Units.smallSpacing
        }

        height: Kirigami.Units.gridUnit * 2
        opacity: root.mainWindow.controlsVisible ? 1 : 0
        visible: opacity !== 0

        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: "white"

        Behavior on opacity {
            OpacityAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        // Pretty gradient ftw
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: Kirigami.Units.gridUnit * 4
            opacity: 0.6
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "black" }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
            }
            height: parent.anchors.bottomMargin
            opacity: 0.6
            color: "black"
        }

        Controls.Slider {
            id: timeSlider

            // NOTE: Screen reader reports raw numbers, not sure if there's any way around it
            Accessible.name: i18n("Seek slider")

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.top
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
            }

            value: pressed ? 0 : videoPlayer.position // don't change value while we drag
            to: videoPlayer.duration

            Controls.ToolTip {
                parent: timeSlider.handle
                visible: timeSlider.pressed
                text: KCA.Format.formatDuration(timeSlider.value, KCA.FormatTypes.FoldHours)
            }

            Keys.onLeftPressed: (event) => {
                if (videoPlayer.seekable) {
                    videoPlayer.seekBackward();
                    event.accepted = true;
                }
            }
            Keys.onRightPressed: (event) => {
                if (videoPlayer.seekable) {
                    videoPlayer.seekForward();
                    event.accepted = true;
                }
            }
            // update on release
            onPressedChanged: {
                if (!pressed) {
                    videoPlayer.position = value;
                }
            }
        }

        RowLayout {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
                verticalCenter: parent.verticalCenter
            }

            spacing: Kirigami.Units.smallSpacing

            Controls.ToolButton {
                Accessible.name: i18np("Skip backward 1 second", "Skip backward %1 seconds", 5)
                visible: videoPlayer.duration >= 5000 && !Kirigami.Settings.isMobile
                icon.name: "media-skip-backward"
                enabled: videoPlayer.playbackState != MediaPlayer.StoppedState
                onClicked: {
                    videoPlayer.seekBackward();
                }
            }

            Controls.ToolButton {
                Accessible.name: videoPlayer.playbackState == MediaPlayer.PlayingState ? i18n("Pause playback") : i18n("Continue playback")
                icon.name: videoPlayer.playbackState == MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                onClicked: {
                    if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                        videoPlayer.pause();
                    } else {
                        videoPlayer.play();
                    }
                }
            }

            Controls.ToolButton {
                Accessible.name: i18np("Skip backward 1 second", "Skip forward %1 seconds", 5)
                visible: videoPlayer.duration >= 5000 && !Kirigami.Settings.isMobile
                icon.name: "media-skip-forward"
                enabled: videoPlayer.playbackState != MediaPlayer.StoppedState
                onClicked: {
                    videoPlayer.seekForward();
                }
            }

            Controls.ToolButton {
                Accessible.name: i18n("Mute audio")
                visible: videoPlayer.hasAudio
                icon.name: {
                    if (audioOutput.volume <= 0 || audioOutput.muted) {
                        return "audio-volume-muted-symbolic";
                    } else if (audioOutput.volume <= 0.25) {
                        return "audio-volume-low-symbolic";
                    } else if (audioOutput.volume <= 0.75) {
                        return "audio-volume-medium-symbolic";
                    } else {
                        return "audio-volume-high-symbolic";
                    }
                }
                checkable: true
                checked: audioOutput.muted
                onClicked: { audioOutput.muted = !audioOutput.muted; }
            }

            Controls.Slider {
                id: volumeSlider
                Accessible.name: i18n("Volume slider")
                from: 0
                to: 1
                value: 0.5
                visible: videoPlayer.hasAudio
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                onPressedChanged: audioOutput.muted = false
            }

            Item {
                Layout.fillWidth: true
                height: 1
            }

            Controls.Label {
                text: KCA.Format.formatDuration(videoPlayer.position, KCA.FormatTypes.FoldHours) + " / " +
                      KCA.Format.formatDuration(videoPlayer.duration, KCA.FormatTypes.FoldHours)
            }

            // this local and independed from slideshow to avoid confusion
            Controls.ToolButton {
                Accessible.name: i18n("Repeat current video")
                Controls.ToolTip.text: Accessible.name
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                icon.name: "media-repeat-all-symbolic"
                checkable: true
                checked: videoPlayer.loops === MediaPlayer.Infinite
                onClicked: {
                    if (videoPlayer.loops === MediaPlayer.Infinite) {
                        // BUG QTBUG-138417: We are unable to set 0, so the video will loop once more if it is already playing.
                        //                   A value of 0 is ignored and the video would loop forever if set.
                        videoPlayer.loops = 1;
                    } else {
                        videoPlayer.loops = MediaPlayer.Infinite;
                    }
                }
            }
        }
    }
}
