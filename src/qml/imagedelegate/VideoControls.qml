/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects as Effects
import QtMultimedia

import org.kde.kirigami as Kirigami

QQC2.Control {
    id: control

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary

    required property Item backgroundSource

    padding: Kirigami.Units.smallSpacing

    background: Kirigami.ShadowedRectangle {

        // This to make the radius of the buttons near the borders exactly concentric,
        // otherwise it looks very janky
        radius: Kirigami.Units.cornerRadius + control.padding

        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.6);

        border {
            width: 1
            color: Qt.alpha(
                Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.4),
                0.6);
        }

        shadow {
            size: Kirigami.Units.gridUnit
            color: Qt.rgba(0, 0, 0, 0.25)
            yOffset: 2
        }

        Effects.MultiEffect {
            anchors.fill: parent
            z: -1

            source: ShaderEffectSource {
                anchors.fill: parent

                sourceRect: Qt.rect(control.x, control.y, control.width, control.height) // X Y wrong?
                sourceItem: control.backgroundSource
            }

            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64

            saturation: 1
            maskEnabled: true
            maskSource: mask

            Item {
                id: mask
                anchors.fill: parent

                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    radius: Kirigami.Units.cornerRadius + control.padding
                }
            }
        }
    }

    contentItem: RowLayout {
        Rectangle {
            color: "red"
            width: 30
            height: 30
        }
    }
}
