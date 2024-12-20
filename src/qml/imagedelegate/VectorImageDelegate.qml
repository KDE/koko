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
import QtQml
import QtMultimedia
import org.kde.kirigami as Kirigami
import org.kde.koko.image as KokoImage

BaseImageDelegate {
    id: root

    loaded: vector.status == KokoImage.VectorImage.Ready
    loading: vector.status == KokoImage.VectorImage.Loading

    sourceWidth: vector.sourceSize.width
    sourceHeight: vector.sourceSize.height

    data: KokoImage.VectorImage {
        id: vector
        anchors.fill: parent
        source: root.source
        sourceClipRect: Qt.rect(-root.contentX, -root.contentY, root.contentWidth, root.contentHeight)
    }
}


