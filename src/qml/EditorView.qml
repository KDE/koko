/*
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kquickimageeditor 1.0 as KQuickImageEditor
import "./Dialog"

Kirigami.Page {
    id: root

    property bool cropping: false
    property bool resizing: false
    property string imagePath
    property bool forceDiscard: false

    signal imageEdited()

    title: i18n("Edit")

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    onBackRequested: (event) => {
        if (imageDoc.edited && !root.forceDiscard) {
            confirmDiscardingChangeDialog.visible = true;
            event.accepted = true;
        }
    }

    function crop() {
        root.cropping = false
        imageDoc.crop(selectionTool.selectionX / editImage.ratioX,
                      selectionTool.selectionY / editImage.ratioY,
                      selectionTool.selectionWidth / editImage.ratioX,
                      selectionTool.selectionHeight / editImage.ratioY);
    }

    function resize() {
        const ratioX = editImage.paintedWidth / editImage.nativeWidth;
        const ratioY = editImage.paintedHeight / editImage.nativeHeight;
        root.resizing = false
        imageDoc.resize(selectionTool.selectionWidth / ratioX, selectionTool.selectionHeight / ratioY);
    }

    actions {
        main: Kirigami.Action {
            id: saveAction
            visible: imageDoc.edited
            text: i18nc("@action:button Save image modification", "Save")
            icon.name: "document-save"
            onTriggered: {
                if (!imageDoc.save()) {
                    msg.type = Kirigami.MessageType.Error
                    msg.text = i18n("Unable to save file. Check if you have the correct permission to edit this file.")
                    msg.visible = true;
                }
                root.imageEdited();
                applicationWindow().pageStack.layers.pop();
            }
        }
        left: Kirigami.Action {
            id: undoAction
            text: i18nc("@action:button Undo modification", "Undo")
            icon.name: "edit-undo"
            onTriggered: {
                if (imageDoc.edited) {
                    imageDoc.undo();
                }
            }
            visible: imageDoc.edited
        }
        contextualActions: [
            Kirigami.Action {
                icon.name: root.cropping ? "dialog-cancel" : "transform-crop"
                text: root.cropping ? i18nc("@action:button", "Cancel") : i18nc("@action:button Crop an image", "Crop");
                onTriggered: root.cropping = !root.cropping;
                visible: !root.resizing
            },
            Kirigami.Action {
                icon.name: "dialog-ok"
                text: i18nc("@action:button Crop an image", "Crop");
                onTriggered: root.crop();
                visible: root.cropping
            },
            Kirigami.Action {
                icon.name: root.resizing ? "dialog-cancel" : "transform-scale"
                text: root.resizing ? i18nc("@action:button", "Cancel") : i18nc("@action:button Resize an image", "Resize");
                onTriggered: root.resizing = !root.resizing;
                visible: !root.cropping
            },
            Kirigami.Action {
                icon.name: "dialog-ok"
                text: i18nc("@action:button Resize an image", "Resize");
                onTriggered: root.resize();
                visible: root.resizing
            },
            Kirigami.Action {
                icon.name: "object-rotate-left"
                text: i18nc("@action:button Rotate an image to the left", "Rotate left");
                onTriggered: imageDoc.rotate(-90);
                visible: !root.cropping && !root.resizing
            },
            Kirigami.Action {
                icon.name: "object-rotate-right"
                text: i18nc("@action:button Rotate an image to the right", "Rotate right");
                onTriggered: imageDoc.rotate(90);
                visible: !root.cropping && !root.resizing
            },
            Kirigami.Action {
                icon.name: "object-flip-vertical"
                text: i18nc("@action:button Mirror an image vertically", "Flip");
                onTriggered: imageDoc.mirror(false, true);
                visible: !root.cropping && !root.resizing
            },
            Kirigami.Action {
                icon.name: "object-flip-horizontal"
                text: i18nc("@action:button Mirror an image horizontally", "Mirror");
                onTriggered: imageDoc.mirror(true, false);
                visible: !root.cropping && !root.resizing
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: QQC2.ToolSeparator {
                    leftPadding: Kirigami.Units.largeSpacing
                    rightPadding: leftPadding
                }
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: QQC2.Label {
                    text: i18nc("@title:group for crop area size spinboxes", "Size:")
                }
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: EditorSpinBox {
                    minimumContentWidth: widthTextMetrics.width
                    from: 1
                    to: editImage.nativeWidth
                    value: selectionTool.selectionWidth / editImage.ratioX
                    onValueModified: selectionTool.selectionWidth = value * editImage.ratioX
                }
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: EditorSpinBox {
                    minimumContentWidth: heightTextMetrics.width
                    from: 1
                    to: editImage.nativeHeight
                    value: selectionTool.selectionHeight / editImage.ratioY
                    onValueModified: selectionTool.selectionHeight = value * editImage.ratioY
                }
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: Item {
                    implicitWidth: Kirigami.Units.largeSpacing
                }
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: QQC2.Label {
                    text: i18nc("@title:group for crop area position spinboxes", "Position:")
                }
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: EditorSpinBox {
                    minimumContentWidth: widthTextMetrics.width
                    from: 0
                    to: editImage.nativeWidth - (selectionTool.selectionWidth / editImage.ratioX)
                    value: selectionTool.selectionX / editImage.ratioX
                    onValueModified: selectionTool.selectionX = value * editImage.ratioX
                }
            },
            Kirigami.Action {
                visible: root.resizing
                displayComponent: EditorSpinBox {
                    minimumContentWidth: heightTextMetrics.width
                    from: 0
                    to: editImage.nativeHeight - (selectionTool.selectionHeight / editImage.ratioY)
                    value: selectionTool.selectionY / editImage.ratioY
                    onValueModified: selectionTool.selectionY = value * editImage.ratioY
                }
            }
        ]
    }

    ConfirmDiscardingChange {
        id: confirmDiscardingChangeDialog
        onDiscardChanges: {
            root.forceDiscard = true;
            applicationWindow().pageStack.layers.pop();
        }
    }

    TextMetrics {
        id: widthTextMetrics
        text: editImage.nativeWidth.toLocaleString(root.locale, 'f', 0)
    }

    TextMetrics {
        id: heightTextMetrics
        text: editImage.nativeHeight.toLocaleString(root.locale, 'f', 0)
    }

    component EditorSpinBox : QQC2.SpinBox {
        id: control
        property real minimumContentWidth: 0
        contentItem: QQC2.TextField {
            id: textField
            implicitWidth: control.minimumContentWidth + leftPadding + rightPadding
            implicitHeight: Math.ceil(contentHeight) + topPadding + bottomPadding
            palette: control.palette
            leftPadding: control.spacing
            rightPadding: control.spacing
            topPadding: 0
            bottomPadding: 0
            text: control.displayText
            font: control.font
            color: Kirigami.Theme.textColor
            selectionColor: Kirigami.Theme.highlightColor
            selectedTextColor: Kirigami.Theme.highlightedTextColor
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            readOnly: !control.editable
            validator: control.validator
            inputMethodHints: control.inputMethodHints
            selectByMouse: true
            background: null
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

    KQuickImageEditor.ImageItem {
        id: editImage
        readonly property real ratioX: editImage.paintedWidth / editImage.nativeWidth;
        readonly property real ratioY: editImage.paintedHeight / editImage.nativeHeight;

        // Assigning this to the contentItem and setting the padding causes weird positioning issues
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit
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
        }

        KQuickImageEditor.ImageDocument {
            id: imageDoc
            path: root.imagePath
        }

        KQuickImageEditor.SelectionTool {
            id: selectionTool
            visible: root.cropping || root.resizing
            width: editImage.paintedWidth
            height: editImage.paintedHeight
            x: editImage.horizontalPadding
            y: editImage.verticalPadding
            KQuickImageEditor.CropBackground {
                anchors.fill: parent
                z: -1
                insideX: selectionTool.selectionX
                insideY: selectionTool.selectionY
                insideWidth: selectionTool.selectionWidth
                insideHeight: selectionTool.selectionHeight
            }
            Loader {
                active: root.resizing
                visible: root.resizing
                x: selectionTool.selectionX
                y: selectionTool.selectionY
                width: selectionTool.selectionWidth
                height: selectionTool.selectionHeight
                sourceComponent: KQuickImageEditor.ImageItem {
                    anchors.fill: parent
                    fillMode: KQuickImageEditor.ImageItem.Stretch
                    image: imageDoc.image
                }
            }
            Connections {
                target: selectionTool.selectionArea
                function onDoubleClicked() {
                    if (root.cropping) {
                        root.crop()
                    } else if (root.resizing) {
                        root.resize()
                    }
                }
            }
        }
        onImageChanged: {
            selectionTool.selectionX = 0
            selectionTool.selectionY = 0
            selectionTool.selectionWidth = Qt.binding(() => selectionTool.width)
            selectionTool.selectionHeight = Qt.binding(() => selectionTool.height)
        }
    }

    footer: Kirigami.InlineMessage {
        id: msg
        type: Kirigami.MessageType.Error
        position: Kirigami.InlineMessage.Footer
        showCloseButton: true
        visible: false
    }
}
