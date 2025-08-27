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
import org.kde.koko

BaseImageDelegate {
    id: root

    loaded: image.status == Image.Ready
    loading: image.status == Image.Loading

    sourceWidth: imageInfo.width
    sourceHeight: imageInfo.height

    Image {
        id: image

        anchors.fill: parent

        source: root.source
        asynchronous: root.preferAsync
        cache: false

        fillMode: Image.PreserveAspectFit

        // Only stop being smooth at >= 400% (matches Gwenview)
        smooth: root.zoomFactor < 4
        // NOTE: mipmap has no effect at >= 100%, but should stay enabled as changes cause the
        // image to reload, showing a black frame unless retainWhileLoading is true, but reloading
        // the image is undesirable and it also causes noisy warning output: "Mipmap settings
        // changed without having image data available."
        mipmap: true

        autoTransform: true
    }

    FileInfo {
        id: imageInfo
        source: root.source
    }
}

