/*
 *   Copyright 2014 by Marco Martin <mart@kde.org>
 *   Copyright 2014 by David Edmundson <davidedmundson@kde.org>
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
import QtQuick.Controls.Styles 1.1 as QtQuickControlStyle
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

import "plasmaprivate" as Private

QtQuickControlStyle.ButtonStyle {
    id: style

    property int minimumWidth
    property int minimumHeight

    label: Item {
        //wrapper is needed as we are adjusting the preferredHeight of the layout from the default
        //and the implicitHeight is implicitly read only
        implicitHeight: buttonContent.Layout.preferredHeight
        implicitWidth: buttonContent.implicitWidth
        RowLayout {
            id: buttonContent
            anchors.fill: parent
            spacing: units.smallSpacing

            Layout.preferredHeight: Math.max(units.iconSizes.small, label.implicitHeight)

            property real minimumWidth: Layout.minimumWidth + style.padding.left + style.padding.right
            onMinimumWidthChanged: {
                if (control.minimumWidth !== undefined) {
                    style.minimumWidth = minimumWidth;
                    control.minimumWidth = minimumWidth;
                }
            }

            property real minimumHeight: Layout.preferredHeight + style.padding.top + style.padding.bottom
            onMinimumHeightChanged: {
                if (control.minimumHeight !== undefined) {
                    style.minimumHeight = minimumHeight;
                    control.minimumHeight = minimumHeight;
                }
            }

            PlasmaCore.IconItem {
                id: icon
                source: "tab-close"
                anchors.verticalCenter: parent.verticalCenter

                implicitHeight: label.implicitHeight * 0.75
                implicitWidth: implicitHeight

                Layout.minimumWidth: valid ? parent.height * 0.75: 0
                Layout.maximumWidth: Layout.minimumWidth
                visible: valid
                Layout.minimumHeight: Layout.minimumWidth
                Layout.maximumHeight: Layout.minimumWidth
                active: control.hovered
                colorGroup: control.hovered || !control.flat ? PlasmaCore.Theme.ButtonColorGroup : PlasmaCore.Theme.NormalColorGroup

                MouseArea {
                    anchors.fill: parent
                    onClicked: control.tagRemoved()
                }
            }

            Rectangle {
                id: tagCircle
                color: control.color
                radius: width * 0.5

                Layout.minimumWidth: parent.height * 0.75
                Layout.maximumWidth: Layout.minimumWidth
                Layout.minimumHeight: Layout.minimumWidth
                Layout.maximumHeight: Layout.minimumWidth
            }

            PlasmaComponents.Label {
                id: label
                Layout.minimumWidth: implicitWidth
                text: control.text
                font: control.font
                visible: control.text != ""
                Layout.fillWidth: true
                height: parent.height
                color: control.hovered || !control.flat ? theme.buttonTextColor : theme.textColor
                horizontalAlignment: icon.valid ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    background: Private.ButtonBackground {}
}
