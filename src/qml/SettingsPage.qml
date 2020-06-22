/*
 * SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Dialogs 1.2 as Dialogs
import QtQuick.Layouts 1.3
import QtQml.Models 2.3

import org.kde.kcm 1.2
import org.kde.kirigami 2.12 as Kirigami

ScrollViewKCM {
    title: i18n("Configure the pictures paths")
    
    view: ListView {
        id:pathList

        Layout.fillWidth: true
        Layout.fillHeight: true
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        model: DelegateModel {
            model: kokoConfig.customPictureDirectory

            delegate: pathDelegate
        }

        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: scrollBar
        }

        Component {
            id: pathDelegate
            
            Kirigami.SwipeListItem {
                id: delegateItem
                QQC2.Label {
                    text: modelData
                }
                actions: [
                    Kirigami.Action {
                        icon.name: 'list-remove'
                        onTriggered: {
                            var oldPaths = kokoConfig.customPictureDirectory
                            oldPaths.splice(delegateItem.DelegateModel.itemsIndex, 1)
                            kokoConfig.customPictureDirectory = configHelper.processPaths(oldPaths)
                        }
                    }
                ]
            }
        }
    }
    
    footer: ColumnLayout {
        RowLayout {
            Layout.alignment: Qt.AlignRight
            QQC2.Button {
                icon.name: "add"
                text: i18n("Add pictures path")
                onClicked: fileDialog.open()
                
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
            QQC2.Button {
                text: i18n("Save")
                onClicked: {
                    kokoConfig.save()
                    pageStack.pop()
                }
            }
        }
    }
}
