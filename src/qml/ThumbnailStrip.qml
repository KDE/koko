/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
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

    displayMarginBeginning: thumbnailView.containerPadding
    displayMarginEnd: thumbnailView.containerPadding
    reuseItems: true

    enum CenteringBehavior {
        NoCentering,
        ImmediateCentering,
        AnimatedCentering
    }

    // Use a custom animation instead of highlightRangeMode as it tends to be very glitchy,
    // see https://bugreports.qt.io/browse/QTBUG-139761
    NumberAnimation {
        id: centerAnimation
        target: thumbnailView
        property: "contentX"
        from: thumbnailView.contentX
        property bool enabled: false
        property int centeringBehavior: ThumbnailStrip.CenteringBehavior.ImmediateCentering
        to: Math.min(thumbnailView.contentWidth - thumbnailView.width,
                Math.max(0,
                    (thumbnailView.delegateSize + thumbnailView.spacing) * thumbnailView.currentIndex - thumbnailView.width/2 + thumbnailView.delegateSize/2))
        onToChanged: {
            if (thumbnailView.currentIndex < 0) {
                return;
            }
            switch (centeringBehavior) {
            case ThumbnailStrip.CenteringBehavior.AnimatedCentering:
                restart();
                break;
            case ThumbnailStrip.CenteringBehavior.ImmediateCentering:
                thumbnailView.contentX = to;
                break;
            default:
                break;
            }

            centeringBehavior = ThumbnailStrip.CenteringBehavior.AnimatedCentering;
        }
    }

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
        if (!thumbnailView.currentItem) {
            return -1;
        }

        let centerOffset = Math.abs(thumbnailView.currentItem.x - delegate.x);
        let delegateSize = delegate.width + thumbnailView.spacing;
        return Math.round(centerOffset / delegateSize);
    }

    delegate: AlbumDelegate {
        id: delegate

        ListView.onPooled: { thumbnailPriority = -1; }
        ListView.onReused: { thumbnailPriority = Qt.binding(() => thumbnailView.calculateThumbnailPriority(delegate)); }
        thumbnailPriority: thumbnailView.calculateThumbnailPriority(delegate)

        width: thumbnailView.delegateSize
        height: thumbnailView.delegateSize

        onClicked: {
            centerAnimation.centeringBehavior = ThumbnailStrip.CenteringBehavior.NoCentering;
            thumbnailView.activated(delegate.index);
        }

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
            opacity: thumbnailView.currentIndex === delegate.index ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
