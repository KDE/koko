/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Window 2.2
import QtQuick.Controls 2.10 as Controls
import QtGraphicalEffects 1.0 as Effects
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.13 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.kquickcontrolsaddons 2.0 as KQA

ListView {
    id: thumbnailView

    signal activated(var index)

    state: applicationWindow().controlsVisible ? "show" : "hidden"

    states: [
        State {
            name: "show"
            PropertyChanges { target: thumbnailView; opacity: 1.0 }
            PropertyChanges { target: thumbnailView; anchors.bottomMargin: 0 }
        },
        State {
            name: "hidden"
            PropertyChanges { target: thumbnailView; opacity: 0.0 }
            PropertyChanges { target: thumbnailView; anchors.bottomMargin: -thumbnailView.height  }
        }
    ]

    transitions: [
        Transition {
            from: "*"
            to: "hidden"
            SequentialAnimation {
                PropertyAnimation {
                    properties: "opacity,anchors.bottomMargin";
                    easing.type: Easing.InCubic
                    duration: Kirigami.Units.longDuration
                }
                PropertyAction {
                    target: thumbnailView
                    property: "visible"
                    value: false
                }
            }
        },
        Transition {
            from: "*"
            to: "show"
            SequentialAnimation {
                PropertyAction {
                    target: thumbnailView
                    property: "visible"
                    value: true
                }
                PropertyAnimation {
                    properties: "opacity,anchors.bottomMargin";
                    easing.type: Easing.OutCubic
                    duration: Kirigami.Units.longDuration * 0.75
                }
            }
        }
    ]

    height: kokoConfig.iconSize
    orientation: Qt.Horizontal
    snapMode: ListView.SnapOneItem

    highlightRangeMode: ListView.ApplyRange
    highlightFollowsCurrentItem: true
    preferredHighlightBegin: height
    preferredHighlightEnd: width - height
    highlightMoveVelocity: -1
    highlightMoveDuration: Kirigami.Units.longDuration

    delegate: AlbumDelegate {
        width: kokoConfig.iconSize + Kirigami.Units.largeSpacing
        height: width
        onClicked: activated()
        onActivated: thumbnailView.activated(model.index)
        modelData: model

        Rectangle {
            z: -1
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
            border.color: Kirigami.Theme.highlightColor
            radius: 2
            opacity: thumbnailView.currentIndex === index ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
