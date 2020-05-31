/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
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
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.7
import QtQuick.Controls 2.1 as QQC2
import org.kde.kquickcontrolsaddons 2.0 as KQA
import org.kde.kirigami 2.12 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.koko.private 1.0 as KokoComponent
import QtQuick.Dialogs 1.0

Kirigami.Page {
    id: rootEditorView
    title: i18n("Edit")
    leftPadding: 0
    rightPadding: 0

    property bool resizing: false;

    function crop() {
        const ratioX = editImage.paintedWidth / editImage.nativeWidth;
        const ratioY = editImage.paintedHeight / editImage.nativeHeight;
        rootEditorView.resizing = false
        imageDoc.crop((resizeRectangle.x - rootEditorView.contentItem.width + editImage.paintedWidth) / ratioX, (resizeRectangle.y - rootEditorView.contentItem.height + editImage.paintedHeight) / ratioY, resizeRectangle.width / ratioX, resizeRectangle.height / ratioY);
    }

    actions {
        right: Kirigami.Action {
            text: i18nc("@action:button Undo modification", "Undo")
            iconName: "edit-undo"
            onTriggered: imageDoc.undo();
            visible: imageDoc.edited
        }
        contextualActions: [
            Kirigami.Action {
                text: i18nc("@action:button Save the image as a new image", "Save As")
                iconName: "document-save-as"
                onTriggered: fileDialog.visible = true;
            },
            Kirigami.Action {
                text: i18nc("@action:button Save the image", "Save")
                iconName: "document-save"
                onTriggered: {
                    if (!imageDoc.save()) {
                        msg.type = Kirigami.MessageType.Error
                        msg.text = i18n("Unable to save file. Check if you have the correct permission to edit this file.")
                        msg.visible = true;
                    }
                }
                visible: imageDoc.edited
            }
        ]
    }

    property string imagePath

    FileDialog {
        id: fileDialog
        title: "Please choose a file"
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

    Koko.ImageDocument {
        id: imageDoc
        path: imagePath
    }

    contentItem: Item {
        id: content
        Flickable {
            id: flickable
            width: rootEditorView.width
            height: rootEditorView.height
            KQA.QImageItem {
                id: editImage
                fillMode: KQA.QImageItem.PreserveAspectFit
                width: rootEditorView.width
                height: rootEditorView.height
                image: imageDoc.visualImage
            }
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
                    text: i18nc("@action:button Rotate an image to the right", "Crop");
                    onTriggered: crop();
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

    KokoComponent.ResizeRectangle {
        id: resizeRectangle

        visible: rootEditorView.resizing

        width: 300
        height: 300
        x: 200
        y: 200

        onAcceptSize: crop();

        Rectangle {
            color: "#3daee9"
            opacity: 0.6
            anchors.fill: parent
        }

        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopLeft
            anchors {
                horizontalCenter: parent.left
                verticalCenter: parent.top
            }
        }
        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomLeft
            anchors {
                horizontalCenter: parent.left
                verticalCenter: parent.bottom
            }
        }
        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.BottomRight
            anchors {
                horizontalCenter: parent.right
                verticalCenter: parent.bottom
            }
        }
        BasicResizeHandle {
            rectangle: resizeRectangle
            resizeCorner: KokoComponent.ResizeHandle.TopRight
            anchors {
                horizontalCenter: parent.right
                verticalCenter: parent.top
            }
        }
    }
}
