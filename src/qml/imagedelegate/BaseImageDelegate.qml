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

import QtQuick 2.15
import QtQml 2.15
import QtMultimedia 5.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1
import org.kde.koko.image 0.1

import ".."

ZoomArea {
    id: root

    required property url source

    required property bool loaded
    required property bool loading

    required property real sourceWidth
    required property real sourceHeight

    required property bool isCurrent

    implicitContentWidth: sourceWidth
    implicitContentHeight: sourceHeight

    /* Using very small min sizes and very large max sizes since there don't seem
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
    minimumZoomSize: 8
    maximumZoomFactor: 100

    Timer {
        id: doubleClickTimer
        interval: Qt.styleHints.mouseDoubleClickInterval + 1
        onTriggered: applicationWindow().controlsVisible = !applicationWindow().controlsVisible
    }
    onClicked: if (mouse.button === Qt.LeftButton) {
        if (applicationWindow().contextDrawer) {
            applicationWindow().contextDrawer.drawerOpen = false
        }
        doubleClickTimer.restart()
    }
    onDoubleClicked: if (mouse.button === Qt.LeftButton) {
        doubleClickTimer.stop()
    }

    onIsCurrentChanged: {
        root.contentWidth = Qt.binding(() => root.defaultContentRect.width)
        root.contentHeight = Qt.binding(() => root.defaultContentRect.height)
    }
}
