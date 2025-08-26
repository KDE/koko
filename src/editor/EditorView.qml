// SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Noah Davis <noahadvs@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtCore
import QtQuick
import QtQml
import QtQuick.Templates as T
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kquickimageeditor as KQuickImageEditor
import org.kde.photos.editor as PhotosEditor

Kirigami.Page {
    id: root

    property string imagePath
    onImagePathChanged: {
        imageView.document.loadImageFromPath(imagePath.replace("file://", ""))
    }

    signal imageEdited()

    title: i18n("Edit")
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    onBackRequested: (event) => {
        if (imageView.document.modified && !root.forceDiscard) {
            confirmDiscardingChangeDialog.visible = true;
            event.accepted = true;
        }
    }

    actions: [
        Kirigami.Action {
            visible: (imageView.document.tool.options !== KQuickImageEditor.AnnotationTool.NoOptions
                              || (imageView.document.tool.type === KQuickImageEditor.AnnotationTool.SelectTool
                              && imageView.document.selectedItem.options !== KQuickImageEditor.AnnotationTool.NoOptions))
            displayComponent: AnnotationOptionsToolBarContents {
                document: imageView.document
            }
        },

        Kirigami.Action {
            separator: true
        },

        Kirigami.Action {
            id: saveAction
            enabled: imageView.document.modified
            text: i18nc("@action:button Save image modification", "Save")
            icon.name: "document-save"
            onTriggered: {
                const ok = imageView.document.saveImage(imagePath.replace("file://", ""));
                if (!ok) {
                    msg.type = Kirigami.MessageType.Error
                    msg.text = i18n("Unable to save file. Check if you have the correct permission to edit this file.")
                    msg.visible = true;
                    return;
                }
                root.imageEdited();
                imageView.document.modified = false;
            }
        },

        Kirigami.Action {
            text: i18nc("@action:button", "Undo")
            icon.name: "edit-undo-symbolic"
            enabled: imageView.document.undoStackDepth > 0
            onTriggered: imageView.document.undo()
            displayHint: Kirigami.DisplayHint.IconOnly
        },
        Kirigami.Action {
            text: i18nc("@action:button", "Redo")
            icon.name: "edit-redo-symbolic"
            enabled: imageView.document.redoStackDepth > 0
            onTriggered: imageView.document.redo()
            displayHint: Kirigami.DisplayHint.IconOnly
        }
    ]

    header: Kirigami.InlineMessage {
        id: msg

        position: Kirigami.InlineMessage.Header
        visible: false
        width: parent.width
    }

    contentItem: RowLayout {
        spacing: 0

        Controls.Pane { // parent is contentItem
            id: annotationsToolBar

            contentItem: AnnotationsToolBarContents {
                id: annotationsToolBarContents

                document: imageView.document
                displayMode: Controls.AbstractButton.IconOnly
                flow: Grid.TopToBottom
                showNoneButton: true
                rememberToolType: true
            }

            background: Rectangle {
                color: parent.palette.window
            }

            Layout.fillHeight: true
        }

        Kirigami.Separator { // parent is contentItem
            id: separator

            Layout.preferredWidth: 1
            Layout.fillHeight: true
        }

        ImageView {
            id: imageView

            showCropTool: annotationsToolBarContents.usingCropTool

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    ConfirmDiscardingChange {
        id: confirmDiscardingChangeDialog

        onDiscardChanges: {
            root.forceDiscard = true;
            (root.QQC2.ApplicationWindow.window as Kirigami.ApplicationWindow).pageStack.layers.pop();
        }
    }

    footer: Controls.ToolBar {
        contentItem: RowLayout {
            spacing: Kirigami.Units.mediumSpacing
            Item {
                Layout.fillWidth: true
            }

            Controls.Label {
                id: zoomLabel
                text: i18n("Zoom:")
            }

            Controls.SpinBox {
                id: zoomEditor
                from: imageView.minZoom * 100
                to: imageView.maxZoom * 100
                stepSize: 25
                value: imageView.currentZoom * 100
                textFromValue: (value, locale) => {
                    return Number(Math.round(value)).toLocaleString(locale, 'f', 0) + locale.percent
                }
                valueFromText: (text, locale) => {
                    return Number.fromLocaleString(locale, text.replace(/\D/g,''))
                }
                Controls.ToolTip.text: i18n("Image Zoom")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                Binding {
                    target: zoomEditor.contentItem
                    property: "horizontalAlignment"
                    value: Text.AlignRight
                    restoreMode: Binding.RestoreNone
                }
                onValueModified: imageView.zoomToPercent(Math.round(value) / 100)
            }
        }
    }
}
