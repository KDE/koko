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
    readonly property alias player: mediaPlayer
    readonly property bool playing: mediaPlayer.playbackState === MediaPlayer.PlayingState
    readonly property alias mediaStatus: mediaPlayer.mediaStatus

    // signals when playback starts and finishes
    signal playbackStarted()
    signal playbackFinished()

    // convenience function
    function play(): void {
        if (mediaPlayer.status != MediaPlayer.Loaded) {
            mediaPlayer.autoPlay = true
        } else {
            mediaPlayer.play();
        }
    }

    function stop(): void {
        mediaPlayer.stop();
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
            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                mediaPlayer.pause();
            } else{
                mediaPlayer.play();
            }
        }
    }

    MediaPlayer {
        id: mediaPlayer

        source: videoPlayerRoot.source

        Component.onCompleted: showFirstFrame()

        onPlaybackStateChanged: if (playbackState === MediaPlayer.StoppedState) {
            videoPlayerRoot.playbackFinished();
            mediaPlayer.showFirstFrame();
        } else if (playbackState === MediaPlayer.PlayingState) {
            videoPlayerRoot.playbackStarted();
        }

        audioOutput: AudioOutput {
            id: audioOutput
            volume: 1 // volumeSlider.value // TODO
        }

        videoOutput: videoOutput

        loops: mediaPlayer.duration >= 5000 ? 1 : MediaPlayer.Infinite // loop short videos

        // When in a stopped state, we are showing a black frame, so change
        // to paused state instead so we have something better to display
        function showFirstFrame(): void {
            if (mediaPlayer.playbackState === MediaPlayer.StoppedState) {
                mediaPlayer.position = 0;
                mediaPlayer.pause();
            }
        }

        function seekForward(): void {
            if (!mediaPlayer.seekable) {
                return;
            }

            if (mediaPlayer.position + 5000 < mediaPlayer.duration) {
                mediaPlayer.position += 5000;
            } else {
                mediaPlayer.stop();
            }
        }

        function seekBackward(): void {
            if (!mediaPlayer.seekable) {
                return;
            }

            mediaPlayer.position -= 5000;
        }
    }

    Rectangle {
        id: videoOutputContainer
        anchors.fill: parent

        implicitWidth: mediaPlayer.metaData.resolution ? mediaPlayer.metaData.resolution.width : 0
        implicitHeight: mediaPlayer.metaData.resolution ? mediaPlayer.metaData.resolution.height : 0

        // VideoControls' blur effect requires that the background isn't transparent, so we need to wrap it
        color: "black"

        VideoOutput {
            id: videoOutput
            anchors.fill: parent

            // Prevents black frame showing before we skip back to start
            endOfStreamPolicy: VideoOutput.KeepLastFrame
        }
    }

    VideoControls {
        anchors.margins: Kirigami.Units.largeSpacing
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        width: (parent.width < Kirigami.Units.gridUnit * 30) ? parent.width - (anchors.margins * 2)
                                                             : Math.max((Kirigami.Units.gridUnit * 30) - (anchors.margins * 2), parent.width * 0.7)

        visible: true // TODO & opacity with layer enabled, mouse timer stuff

        backgroundSource: videoOutputContainer
    }

    /*
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

            value: pressed ? 0 : mediaPlayer.position // don't change value while we drag
            to: mediaPlayer.duration

            Controls.ToolTip {
                parent: timeSlider.handle
                visible: timeSlider.pressed
                text: KCA.Format.formatDuration(timeSlider.value, KCA.FormatTypes.FoldHours)
            }

            Keys.onLeftPressed: (event) => {
                if (mediaPlayer.seekable) {
                    mediaPlayer.seekBackward();
                    event.accepted = true;
                }
            }
            Keys.onRightPressed: (event) => {
                if (mediaPlayer.seekable) {
                    mediaPlayer.seekForward();
                    event.accepted = true;
                }
            }
            // update on release
            onPressedChanged: {
                if (!pressed) {
                    mediaPlayer.position = value;
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
                visible: mediaPlayer.duration >= 5000 && !Kirigami.Settings.isMobile
                icon.name: "media-skip-backward"
                enabled: mediaPlayer.playbackState != MediaPlayer.StoppedState
                onClicked: {
                    mediaPlayer.seekBackward();
                }
            }

            Controls.ToolButton {
                Accessible.name: mediaPlayer.playbackState == MediaPlayer.PlayingState ? i18n("Pause playback") : i18n("Continue playback")
                icon.name: mediaPlayer.playbackState == MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                onClicked: {
                    if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                        mediaPlayer.pause();
                    } else {
                        mediaPlayer.play();
                    }
                }
            }

            Controls.ToolButton {
                Accessible.name: i18np("Skip backward 1 second", "Skip forward %1 seconds", 5)
                visible: mediaPlayer.duration >= 5000 && !Kirigami.Settings.isMobile
                icon.name: "media-skip-forward"
                enabled: mediaPlayer.playbackState != MediaPlayer.StoppedState
                onClicked: {
                    mediaPlayer.seekForward();
                }
            }

            Controls.ToolButton {
                Accessible.name: i18n("Mute audio")
                visible: mediaPlayer.hasAudio
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
                visible: mediaPlayer.hasAudio
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                onPressedChanged: audioOutput.muted = false
            }

            Item {
                Layout.fillWidth: true
                height: 1
            }

            Controls.Label {
                text: KCA.Format.formatDuration(mediaPlayer.position, KCA.FormatTypes.FoldHours) + " / " +
                      KCA.Format.formatDuration(mediaPlayer.duration, KCA.FormatTypes.FoldHours)
            }

            // this local and independed from slideshow to avoid confusion
            Controls.ToolButton {
                Accessible.name: i18n("Repeat current video")
                Controls.ToolTip.text: Accessible.name
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                icon.name: "media-repeat-all-symbolic"
                checkable: true
                checked: mediaPlayer.loops === MediaPlayer.Infinite
                onClicked: {
                    if (mediaPlayer.loops === MediaPlayer.Infinite) {
                        // BUG QTBUG-138417: We are unable to set 0, so the video will loop once more if it is already playing.
                        //                   A value of 0 is ignored and the video would loop forever if set.
                        mediaPlayer.loops = 1;
                    } else {
                        mediaPlayer.loops = MediaPlayer.Infinite;
                    }
                }
            }
        }
    }
    */
}
