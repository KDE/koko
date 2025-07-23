/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko

ListView {
    id: thumbnailView

    required property int containerPadding

    readonly property int delegateSize: Koko.Config.iconSize + Kirigami.Units.largeSpacing

    readonly property int remainingWidth: Math.max(0, thumbnailView.width
                                                      - (thumbnailView.count * thumbnailView.delegateSize)
                                                      - ((thumbnailView.count - 1) * thumbnailView.spacing))

    signal activated(int index)

    orientation: Qt.Horizontal

    spacing: thumbnailView.containerPadding

    highlightRangeMode: ListView.ApplyRange
    highlightFollowsCurrentItem: true
    preferredHighlightBegin: (width - thumbnailView.delegateSize) / 2
    preferredHighlightEnd: (width + thumbnailView.delegateSize) / 2
    highlightMoveVelocity: -1
    highlightMoveDuration: Kirigami.Units.longDuration
    displayMarginBeginning: thumbnailView.containerPadding
    displayMarginEnd: thumbnailView.containerPadding
    reuseItems: true

    // Center content when there aren't enough items to fill the width
    header: Item {
        width: Math.max(0, thumbnailView.remainingWidth / 2)
    }

    footer: Item {
        width: Math.max(0, thumbnailView.remainingWidth / 2)
    }

    // Center when width changes (e.g. due to window resizing or animations)
    onWidthChanged: positionViewAtIndex(currentIndex, ListView.Center)

    // Instantiate delegates to fill width * 2 left and right
    cacheBuffer: width * 2

    // Prioritise thumbnailing delegates closest to the highlighted item
    function calculateThumbnailPriority(delegate: Item): int {
        let centerOffset = Math.abs(thumbnailView.currentItem.x - delegate.x);
        let delegateSize = delegate.width + thumbnailView.spacing;
        return Math.round(centerOffset / delegateSize);
    }

    delegate: AlbumDelegate {
        id: delegate

        view: thumbnailView

        width: thumbnailView.delegateSize
        height: thumbnailView.delegateSize

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
