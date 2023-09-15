/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Window
import QtQuick.Controls 2 as Controls
import QtQuick.Layouts
import org.kde.kirigami 2 as Kirigami
import org.kde.koko as Koko
import org.kde.kquickcontrolsaddons 2 as KQA

ListView {
    id: thumbnailView

    signal activated(int index)

    orientation: Qt.Horizontal
    snapMode: ListView.SnapOneItem

    highlightRangeMode: ListView.ApplyRange
    highlightFollowsCurrentItem: true
    preferredHighlightBegin: height
    preferredHighlightEnd: width - height
    highlightMoveVelocity: -1
    highlightMoveDuration: Kirigami.Units.longDuration

    // same spacing as padding in thumbnailScrollView, so that delegates don't pop out of existence
    // we don't do margins as that cause a host of issues, including a crash in rtl
    displayMarginBeginning: Kirigami.Units.smallSpacing
    displayMarginEnd: Kirigami.Units.smallSpacing

    delegate: AlbumDelegate {
        id: delegate

        width: kokoConfig.iconSize + Kirigami.Units.largeSpacing
        height: kokoConfig.iconSize + Kirigami.Units.largeSpacing

        onClicked: thumbnailView.activated(delegate.index)

        Controls.ToolTip.text: Koko.DirModelUtils.fileNameOfUrl(delegate.imageurl)
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

        DragHandler {
            xAxis.enabled: false
            yAxis.enabled: false
        }

        background: Item {}

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
