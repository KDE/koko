/*
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.10
import QtQuick.Controls 2.1 as QQC2
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.3
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kquickimageeditor 1.0 as KQuickImageEditor
import QtGraphicalEffects 1.12
import Qt.labs.platform 1.0 as Platform

Kirigami.Page {
    id: rootEditorView

    property bool resizing: false;
    required property string imagePath

    signal imageEdited();

    title: i18n("Edit")
    leftPadding: 0
    rightPadding: 0

    function crop() {
        const ratioX = editImage.paintedWidth / editImage.nativeWidth;
        const ratioY = editImage.paintedHeight / editImage.nativeHeight;
        rootEditorView.resizing = false
        imageDoc.crop(resizeRectangle.insideX / ratioX, resizeRectangle.insideY / ratioY, resizeRectangle.insideWidth / ratioX, resizeRectangle.insideHeight / ratioY);
    }

    actions {
        left: Kirigami.Action {
            id: undoAction
            text: i18nc("@action:button Undo modification", "Undo")
            iconName: "edit-undo"
            onTriggered: {
                if (imageDoc.edited) {
                    imageDoc.undo();
                }
            }
            visible: imageDoc.edited
        }
        main: Kirigami.Action {
            id: okAction
            text: i18nc("@action:button Accept image modification", "Accept")
            iconName: "dialog-ok"
            onTriggered: {
                if (!imageDoc.save()) {
                    msg.type = Kirigami.MessageType.Error
                    msg.text = i18n("Unable to save file. Check if you have the correct permission to edit this file.")
                    msg.visible = true;
                }
                rootEditorView.imageEdited();
                applicationWindow().pageStack.layers.pop();
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: i18n("Save As")
        folder: shortcuts.home
        selectMultiple: false
        selectExisting: false
        onAccepted: {
            if (imageDoc.saveAs(fileDialog.fileUrl)) {;
                imagePath = fileDialog.fileUrl;
                msg.type = Kirigami.MessageType.Information
                msg.text = i18n("You are now editing a new file.")
                msg.visible = true;
            } else {
                msg.type = Kirigami.MessageType.Error
                msg.text = i18n("Unable to save file. Check if you have the correct permission to edit this file.")
                msg.visible = true;
            }
            fileDialog.close()
        }
        onRejected: {
            fileDialog.close()
        }
        Component.onCompleted: visible = false
    }



    contentItem: KQuickImageEditor.ImageItem {
        id: editImage
        fillMode: KQuickImageEditor.ImageItem.PreserveAspectFit
        image: imageDoc.image

        Shortcut {
            sequence: StandardKey.Undo
            onActivated: undoAction.trigger();
        }

        Shortcut {
            sequences: [StandardKey.Save, "Enter"]
            onActivated: saveAction.trigger();
        }

        Shortcut {
            sequence: StandardKey.SaveAs
            onActivated: saveAsAction.trigger();
        }    anchors.fill: parent

        KQuickImageEditor.ImageDocument {
            id: imageDoc
            path: rootEditorView.imagePath
        }
    }

    header: QQC2.ToolBar {
        contentItem: Kirigami.ActionToolBar {
            id: actionToolBar
            display: QQC2.Button.TextBesideIcon
            actions: [
                Kirigami.Action {
                    iconName: rootEditorView.resizing ? "dialog-cancel" : "transform-crop"
                    text: rootEditorView.resizing ? i18n("Cancel") : i18nc("@action:button Crop an image", "Crop");
                    onTriggered: rootEditorView.resizing = !rootEditorView.resizing;
                },
                Kirigami.Action {
                    iconName: "dialog-ok"
                    visible: rootEditorView.resizing
                    text: i18nc("@action:button Crop an image", "Crop");
                    onTriggered: rootEditorView.crop();
                },
                Kirigami.Action {
                    iconName: "object-rotate-left"
                    text: i18nc("@action:button Rotate an image to the left", "Rotate left");
                    onTriggered: imageDoc.rotate(-90);
                    visible: !rootEditorView.resizing
                },
                Kirigami.Action {
                    iconName: "object-rotate-right"
                    text: i18nc("@action:button Rotate an image to the right", "Rotate right");
                    onTriggered: imageDoc.rotate(90);
                    visible: !rootEditorView.resizing
                },
                Kirigami.Action {
                    iconName: "object-flip-vertical"
                    text: i18nc("@action:button Mirror an image vertically", "Flip");
                    onTriggered: imageDoc.mirror(false, true);
                    visible: !rootEditorView.resizing
                },
                Kirigami.Action {
                    iconName: "object-flip-horizontal"
                    text: i18nc("@action:button Mirror an image horizontally", "Mirror");
                    onTriggered: imageDoc.mirror(true, false);
                    visible: !rootEditorView.resizing
                }
            ]
        }
    }

    footer: Kirigami.InlineMessage {
        id: msg
        type: Kirigami.MessageType.Error
        showCloseButton: true
        visible: false
    }

    KQuickImageEditor.ResizeRectangle {
        id: resizeRectangle

        visible: rootEditorView.resizing

        width: editImage.paintedWidth
        height: editImage.paintedHeight
        x: 0
        y: editImage.verticalPadding

        insideX: 100
        insideY: 100
        insideWidth: 100
        insideHeight: 100

        onAcceptSize: rootEditorView.crop();
    }
}
