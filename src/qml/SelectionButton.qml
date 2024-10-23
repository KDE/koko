// SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.koko as Koko

QQC2.AbstractButton {
    id: root

    required property bool selected
    required property int index
    property QtObject iconMouseArea: iconMouseArea

    width: Kirigami.Units.iconSizes.smallMedium
    height: width
    z: gridView.z + 2

    onClicked: if (root.selected) {
        gridView.model.toggleSelected(root.index)
    } else {
        gridView.model.setSelected(root.index)
    }

    contentItem: Kirigami.Icon {
        source: root.selected ? "emblem-remove" : "emblem-added"
    }

    Behavior on opacity {
        OpacityAnimator {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }
}
