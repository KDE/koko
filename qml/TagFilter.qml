/*
 *   Copyright 2014 by Vishesh Handa <vhanda@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

ColumnLayout {
    id: rootLayout

    ToolButton {
        id: button

        property font font: theme.defaultFont
        property string color
        property bool flat: true
        signal tagRemoved

        property var colors: ["red", "green", "black"]
        text: "Wallpapers"

        style: TagFilterButtonStyle {}

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop

        property bool expanded: false
        onClicked: {
            expanded = !expanded
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignTop

        Item {
            Layout.minimumWidth: units.largeSpacing
            Layout.maximumWidth: Layout.minimumWidth
        }

        TagEditor {
            id: editor
            visible: button.expanded
        }
    }
}
