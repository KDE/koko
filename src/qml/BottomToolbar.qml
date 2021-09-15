/*
 * Copyright 2021 Devin Lin <espidev@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.12 as Kirigami

ToolBar {
    id: toolbarRoot
    padding: 0

    signal filterBy(string value, string query)
    property alias toolbarHeight: rowLayout.implicitHeight

    background: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
        color: Kirigami.Theme.backgroundColor
        anchors.fill: parent
    }

    RowLayout {
        id: rowLayout
        property real marginsWidth: parent.width - Math.min(Kirigami.Units.gridUnit * 25, parent.width)

        anchors.fill: parent
        anchors.leftMargin: Math.round(marginsWidth / 2)
        anchors.rightMargin: Math.round(marginsWidth / 2)

        spacing: 0
        Repeater {
            model: ListModel {
                // we can't use i18n with ListElement
                Component.onCompleted: {
                    append({"name": i18n("Photos"), "filter": "Years", "icon": "photo"});
                    append({"name": i18n("Favourites"), "filter": "Favorites", "icon": "emblem-favorite-symbolic"});
                    append({"name": i18n("Files"), "filter": "Folders", "icon": "folder-symbolic"});
                }
            }

            Rectangle {
                Layout.minimumWidth: parent.width / 3
                Layout.maximumWidth: parent.width / 3
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3 + Kirigami.Units.smallSpacing * 2
                Layout.alignment: Qt.AlignCenter

                Kirigami.Theme.colorSet: Kirigami.Theme.Window
                Kirigami.Theme.inherit: false

                color: mouseArea.pressed ? Qt.darker(Kirigami.Theme.backgroundColor, 1.1) :
                    mouseArea.containsMouse ? Qt.darker(Kirigami.Theme.backgroundColor, 1.03) : Kirigami.Theme.backgroundColor

                property bool isCurrentPage: model.filter == root.currentFilter

                Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

                // top highlight rectangle (if delegate is selected)
                Rectangle {
                    id: highlightRectangle
                    opacity: isCurrentPage ? 1 : 0
                    color: Kirigami.Theme.highlightColor
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2

                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration } }
                }
                Rectangle {
                    id: highlightShadow
                    opacity: isCurrentPage ? 0.3 : 0
                    anchors.top: highlightRectangle.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: highlightRectangle.color }
                        GradientStop { position: 1.0; color: "transparent" }
                    }

                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration } }
                }

                // mouse/touch event
                MouseArea {
                    id: mouseArea
                    hoverEnabled: true
                    anchors.fill: parent
                    onClicked: {
                        if (!isCurrentPage) {
                            toolbarRoot.filterBy(model.filter, model.query)
                        }
                    }
                }

                // delegate content
                ColumnLayout {
                    id: itemColumn
                    anchors.fill: parent
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    anchors.bottomMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: model.icon
                        isMask: true
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                        Layout.preferredHeight: Math.round(Kirigami.Units.iconSizes.small * 1.5)
                        Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.small * 1.5)

                        opacity: isCurrentPage ? 1 : 0.7
                        color: isCurrentPage ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.highlightColor, Kirigami.Theme.textColor, 0.5) : Kirigami.Theme.textColor

                        Behavior on color { ColorAnimation {} }
                        Behavior on opacity { NumberAnimation {} }
                    }

                    Label {
                        text: i18n(model.name)
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle

                        opacity: isCurrentPage ? 1 : 0.7
                        color: isCurrentPage ? Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.highlightColor, Kirigami.Theme.textColor, 0.5) : Kirigami.Theme.textColor
                        font.bold: isCurrentPage
                        font.family: Kirigami.Theme.smallFont.family
                        font.pointSize: Kirigami.Theme.smallFont.pointSize

                        Behavior on color { ColorAnimation {} }
                        Behavior on opacity { NumberAnimation {} }
                    }
                }
            }
        }
    }
}


