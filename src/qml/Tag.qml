/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.12
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.10 as Controls
import org.kde.kirigami 2.13 as Kirigami

Rectangle {
    id: tagRoot
    property string text
    property alias icon: toolButton.icon
    property alias actionText: toolButton.text

    property bool reverse: false
    width: tag.width
    height: tag.height
    color: Kirigami.Theme.alternateBackgroundColor
    border.width: 1
    radius: height / 2
    border.color: Kirigami.Theme.disabledTextColor
    signal clicked()
    RowLayout {
        id: tag
        Controls.Label {
            visible: tagRoot.reverse
            Layout.leftMargin: Kirigami.Units.smallSpacing * 3
            text: tagRoot.text
        }
        Controls.ToolButton {
            id: toolButton
            // there's no size smaller than small unfortunately
            icon.width: Kirigami.Settings.isMobile ? Kirigami.Units.iconSizes.small : 16 * Kirigami.Units.devicePixelRatio
            icon.height: Kirigami.Settings.isMobile ? Kirigami.Units.iconSizes.small : 16 * Kirigami.Units.devicePixelRatio
            display: Controls.AbstractButton.IconOnly
            Layout.leftMargin: tagRoot.reverse ? 0 : Kirigami.Units.smallSpacing
            Layout.rightMargin: tagRoot.reverse ? Kirigami.Units.smallSpacing : 0
            onClicked: tagRoot.clicked()
        }
        Controls.Label {
            visible: !tagRoot.reverse
            Layout.rightMargin: Kirigami.Units.smallSpacing * 3
            text: tagRoot.text
        }
    }
}
