// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.12 as Kirigami
import org.kde.koko 0.1 as Koko

QQC2.Menu {
    required property url fileUrl
    required property QtObject model
    required property bool isInTrash

    Component {
        id: createFolderSheetComponent
        Kirigami.OverlaySheet {
            id: createFolderSheet
            header: Kirigami.Heading {
                level: 2
                text: i18n("New Folder")
            }
            contentItem: ColumnLayout {
                QQC2.Label {
                    text: i18n("Create new folder in %1:", Koko.DirModelUtils.directoryOfUrl(fileUrl.toString().replace("file:/", "")).toString().replace("file:/", ""))
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                QQC2.TextField {
                    id: createFolderSheetField
                    text: i18nc("Default name for the new folder", "New Folder")
                    Layout.fillWidth: true
                }
            }
            footer: RowLayout {
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Button {
                    icon.name: "dialog-ok"
                    text: i18n("Ok")
                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        Koko.DirModelUtils.mkdir(Koko.DirModelUtils.directoryOfUrl(fileUrl.toString().replace("file://", "")) + "/" + createFolderSheetField.text);
                        createFolderSheet.close();
                    }
                }
                QQC2.Button {
                    Layout.alignment: Qt.AlignRight
                    icon.name: "dialog-cancel"
                    text: i18n("Cancel")
                    onClicked: createFolderSheet.close()
                }
            }
        }
    }
    QQC2.MenuItem {
        text: i18n("Create Folder")
        onTriggered: {
            const sheet = createFolderSheetComponent.createObject(applicationWindow());
            sheet.open();
        }
    }
    QQC2.MenuSeparator {}

    QQC2.MenuItem {
        text: i18n("Rename")
    }
    QQC2.MenuItem {
        text: i18n("Restore")
        visible: isInTrash
        onTriggered: model.restoreSelection()
    }
    QQC2.MenuItem {
        text: i18n("Delete")
        visible: !isInTrash
        onTriggered: model.deleteSelection()
    }

    QQC2.MenuSeparator {}

    QQC2.MenuItem {
        text: i18n("Open With")
        onTriggered: model.openSelection()
    }
}
