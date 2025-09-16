/*
 *  SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls

import org.kde.kirigami as Kirigami

Controls.ToolButton {
    id: pathButton

    property alias pathString: label.text

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                implicitContentHeight + topPadding + bottomPadding)

    leftPadding: Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.largeSpacing
    topPadding: Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.largeSpacing
    spacing: Kirigami.Units.smallSpacing

    Accessible.name: label.text

    Controls.ToolTip.text: label.text
    Controls.ToolTip.visible: hovered && label.truncated && label.text.length > 0
    Controls.ToolTip.delay: Kirigami.Units.toolTipDelay

    contentItem: Controls.Label {
        id: label
        elide: Text.ElideMiddle
    }
}
