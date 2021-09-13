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
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1

BaseImageDelegate {
    id: root

    loaded: image.status == Image.Ready
    loading: image.status == Image.Loading

    sourceWidth: imageInfo.width
    sourceHeight: imageInfo.height

    AnimatedImage {
        id: image

        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: root.source
        smooth: root.zoomFactor < 1
        autoTransform: true
        asynchronous: true
        cache: false
    }

    FileInfo {
        id: imageInfo
        source: root.source
    }
}


