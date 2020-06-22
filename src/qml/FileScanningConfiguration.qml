/*
   SPDX-FileCopyrightText: 2017 (c) Matthieu Gallien <matthieu_gallien@yahoo.fr>

   SPDX-License-Identifier: LGPL-3.0-or-later
 */

import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQml.Models 2.3
import QtQuick.Dialogs 1.2 as Dialogs
import org.kde.kirigami 2.12 as Kirigami

ColumnLayout {
    spacing: 0
    Layout.fillHeight: true
    Layout.fillWidth: true

    Component {
        id: highlightBar

        Rectangle {
            width: 200; height: 50
            color: Kirigami.Theme.highlightColor
        }
    }

    Component {
        id: pathDelegate

        Item {
            id: delegateItem

            height: 3 * 30

            width: scrollBar.visible ? pathList.width - scrollBar.width : pathList.width

            Rectangle {
                anchors.fill: parent
                anchors.margins: 0.1 * 30

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    onEntered: pathList.currentIndex = delegateItem.DelegateModel.itemsIndex

                    Label {
                        text: modelData

                        anchors.centerIn: parent
                    }

                    ToolButton {
                        icon.name: 'list-remove'

                        Accessible.onPressAction: onClicked

                        anchors.top: parent.top
                        anchors.right: parent.right

                        onClicked: {
                            var oldPaths = kokoConfig.customPictureDirectory
                            oldPaths.splice(delegateItem.DelegateModel.itemsIndex, 1)
                            kokoConfig.customPictureDirectory = configHelper.processPaths(oldPaths)
                        }
                    }
                }
            }
        }
    }

    ListView {
        id:pathList

        Layout.fillWidth: true
        Layout.fillHeight: true
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        model: DelegateModel {
            model: kokoConfig.customPictureDirectory

            delegate: pathDelegate
        }

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
        }

        highlight: highlightBar
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.leftMargin: !LayoutMirroring.enabled ? (0.3 * 30) : 0
        Layout.rightMargin: LayoutMirroring.enabled ? (0.3 * 30) : 0

        Button {
            text: i18n("Add new path")
            onClicked: fileDialog.open()

            Accessible.onPressAction: onClicked

            Layout.alignment: Qt.AlignTop | Qt.AlignLeft

            Dialogs.FileDialog {
                id: fileDialog
                title: i18n("Choose a Folder")
                folder: shortcuts.home
                selectFolder: true

                visible: false

                onAccepted: {
                    var oldPaths = kokoConfig.customPictureDirectory
                    oldPaths.push(fileDialog.fileUrls)
                    kokoConfig.customPictureDirectory = configHelper.processPaths(oldPaths)
                }
            }
        }
    }
}
