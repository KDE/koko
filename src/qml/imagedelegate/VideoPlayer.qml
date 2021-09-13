/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.15 as Kirigami
import QtMultimedia 5.15
import org.kde.kcoreaddons 1.0 as KCA

Item {
    id: videoPlayerRoot

    // `required` here breaks stuff
    property string source
    readonly property alias player: videoPlayer
    readonly property bool playing: videoPlayer.playbackState === MediaPlayer.PlayingState
    readonly property alias status: videoPlayer.status

    // signals when playback starts and finishes
    signal playbackStarted()
    signal playbackFinished()

    // convenience function
    function play() {
        if (videoPlayer.status != MediaPlayer.Loaded) {
            videoPlayer.autoPlay = true
        } else {
            videoPlayer.play();
        }
    }

    function stop() {
        videoPlayer.stop();
    }

    implicitWidth: videoPlayer.implicitWidth
    implicitHeight: videoPlayer.implicitHeight

    Timer {
        id: doubleClickTimer
        interval: 150
        onTriggered: {
            applicationWindow().controlsVisible = !applicationWindow().controlsVisible;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (applicationWindow().contextDrawer) {
                applicationWindow().contextDrawer.drawerOpen = false;
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

    Video {
        id: videoPlayer
        implicitWidth: videoPlayer.metaData.resolution ? videoPlayer.metaData.resolution.width : 0
        implicitHeight: videoPlayer.metaData.resolution ? videoPlayer.metaData.resolution.height : 0
        anchors.fill: parent
        loops: videoPlayer.duration >= 5000 ? 0 : MediaPlayer.Infinite // loop short videos
        // See https://doc.qt.io/qt-5/qml-qtmultimedia-qtmultimedia.html#convertVolume-method
        volume: QtMultimedia.convertVolume(volumeSlider.value,
                            QtMultimedia.LogarithmicVolumeScale,
                            QtMultimedia.LinearVolumeScale)
        source: videoPlayerRoot.source
        onPlaying: videoPlayerRoot.playbackStarted()
        onStopped: videoPlayerRoot.playbackFinished()

        function seekForward() {
            if (videoPlayer.position + 5000 < videoPlayer.duration) {
                videoPlayer.seek(videoPlayer.position + 5000);
            } else {
                videoPlayer.seek(0);
                videoPlayer.stop();
            }
        }

        function seekBackward() {
            videoPlayer.seek(videoPlayer.position - 5000);
        }
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

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Kirigami.Units.smallSpacing

        height: Kirigami.Units.gridUnit * 2
        opacity: applicationWindow().controlsVisible ? 1 : 0
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
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Kirigami.Units.gridUnit * 4
            opacity: 0.6
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "black" }
            }
        }

        Rectangle {
            anchors.left:parent.left
            anchors.right:parent.right
            anchors.top: parent.bottom
            height: parent.anchors.bottomMargin
            opacity: 0.6
            color: "black"
        }

        Controls.Slider {
            id: timeSlider

            // NOTE: Screen reader reports raw numbers, not sure if there's any way around it
            Accessible.name: i18n("Seek slider")

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.top
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing

            value: pressed ? 0 : videoPlayer.position // don't change value while we drag
            to: videoPlayer.duration

            Controls.ToolTip {
                parent: timeSlider.handle
                visible: timeSlider.pressed
                text: KCA.Format.formatDuration(timeSlider.value, KCA.FormatTypes.FoldHours)
            }

            Keys.onLeftPressed: {
                videoPlayer.seekBackward();
                event.accepted = true;
            }
            Keys.onRightPressed: {
                videoPlayer.seekForward();
                event.accepted = true;
            }
            // update on release
            onPressedChanged: {
                if (!pressed) {
                    videoPlayer.seek(value);
                }
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            anchors.verticalCenter: parent.verticalCenter
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
                Accessible.name: videoPlayer.muted ? i18n("Unmute audio") : i18n("Mute audio")
                visible: videoPlayer.hasAudio
                icon.name: videoPlayer.muted ? "audio-volume-muted" :
                           volumeSlider.value == 0 ? "audio-volume-low" :
                           volumeSlider.value >= 0.5 ? "audio-volume-high" : "audio-volume-medium"
                onClicked: {
                    videoPlayer.muted = !videoPlayer.muted;
                }
            }

            Controls.Slider {
                id: volumeSlider
                Accessible.name: i18n("Volume slider")
                value: 1
                visible: videoPlayer.hasAudio
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                onPressedChanged: videoPlayer.muted = false
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
                // Follows Elisa's convention
                Accessible.name: videoPlayer.loops == MediaPlayer.Infinite ? i18n("Repeat current video") : i18n("Don't repeat current video")
                Controls.ToolTip.text: Accessible.name
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                icon.name: videoPlayer.loops == MediaPlayer.Infinite ? "media-repeat-single" : "media-repeat-none"
                onClicked: {
                    if (videoPlayer.loops == MediaPlayer.Infinite) {
                        videoPlayer.loops = 0;
                    } else {
                        videoPlayer.loops = MediaPlayer.Infinite;
                    }
                }
            }
        }
    }
}
