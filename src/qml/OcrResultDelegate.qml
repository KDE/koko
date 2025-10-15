/*
 * SPDX-FileCopyrightText: (C) 2025 Florian RICHER <florian.richer@protonmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls as Controls
import org.kde.koko as Koko
import org.kde.kirigami as Kirigami

Item {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    required property Image image
    required property real zoomFactor

    Repeater {
        model: Koko.Ocr.ocrResult

        delegate: Rectangle {
            id: ocrRect
            x: image.x + modelData.x * zoomFactor
            y: image.y + modelData.y * zoomFactor
            width: modelData.width * zoomFactor
            height: modelData.height * zoomFactor
            border.width: 2
            border.color: Kirigami.Theme.backgroundColor
            color: Kirigami.Theme.backgroundColor

            Controls.Label {
                anchors.centerIn: parent
                text: modelData.text
                color: Kirigami.Theme.textColor

                // Apply the zoom also on the text size
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * zoomFactor
            }

            MouseArea {
                anchors.fill: ocrRect

                onClicked: {
                    clipboard.content = modelData.text
                    showPassiveNotification(i18n("Text copied to the clipboard"))
                }
            }
        }
    }
}
