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
import org.kde.koko as Koko
import org.kde.kirigami as Kirigami
import org.kde.kquickimageeditor as KQuickImageEditor
import org.kde.photos.editor as PhotosEditor

Kirigami.Page {
    id: root

    required property Kirigami.ApplicationWindow mainWindow

    property string imagePath
    onImagePathChanged: {
        imageView.document.setBaseImage(imagePath.replace("file://", ""))
    }

    signal imageEdited()

    title: i18n("Edit")
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    function save(): bool {
        const ok = imageView.document.saveImage(imagePath.replace("file://", ""));
        if (!ok) {
            root.msg.type = Kirigami.MessageType.Error
            root.msg.text = i18n("Unable to save file. Check if you have the correct permissions to save this file.")
            root.msg.visible = true;

            return false;
        }

        root.imageEdited();
        imageView.document.modified = false;

        return true;
    }

    onBackRequested: (event) => {
        if (imageView.document.modified) {
            confirmDiscardingChangesDialog.visible = true;
            event.accepted = true;
        }
    }

    // Get the scale for each axis
    function getScale(matrix: matrix4x4): vector3d {
        return Qt.vector3d(Math.sqrt(matrix.m11**2 + matrix.m21**2 + matrix.m31**2),
                           Math.sqrt(matrix.m12**2 + matrix.m22**2 + matrix.m32**2),
                           Math.sqrt(matrix.m13**2 + matrix.m23**2 + matrix.m33**2))
    }

    // Get just the z rotation in degrees
    function getZDegrees(matrix: matrix4x4): real {
        return Math.atan2(matrix.m21, matrix.m11) // in radians
            * (180 / Math.PI) // to degrees
    }

    // The document scale must be undone and later reapplied to rotate correctly
    // from the viewer's perspective.
    function rotateForViewer(matrix: matrix4x4, scale: vector3d, appliedZDegrees: real): void {
        matrix.scale(1 / scale.x, 1 / scale.y, 1 / scale.z)
        matrix.rotate(appliedZDegrees, Qt.vector3d(0, 0, 1))
        matrix.scale(scale)
    }

    // The document rotation must be undone and later reapplied to scale
    // correctly from the viewer's perspective.
    function scaleForViewer(matrix: matrix4x4, zDegrees: real, appliedXScale: real, appliedYScale: real): void {
        const rotationAxes = Qt.vector3d(0, 0, 1)
        matrix.rotate(-zDegrees, rotationAxes)
        matrix.scale(appliedXScale, appliedYScale, 1)
        matrix.rotate(zDegrees, rotationAxes)
    }

    actions: [
        Kirigami.Action {
            id: startResizeAction
            checkable: true
            checked: false
            icon.name: checked ? "dialog-cancel" : "transform-scale"
            text: checked ? i18nc("@action:button", "Cancel") : i18nc("@action:button Resize an image", "Resize");
        },

        Kirigami.Action {
            id: finishResizeAction
            property size targetSize: imageView.document.imageSize
            icon.name: "dialog-ok"
            text: i18nc("@action:button Resize an image", "Resize");
            onTriggered: {
                let matrix = Qt.matrix4x4()
                const sx = targetSize.width / imageView.document.imageSize.width
                const sy = targetSize.height / imageView.document.imageSize.height
                scaleForViewer(matrix, getZDegrees(imageView.document.transform),
                               sx, sy)
                imageView.document.applyTransform(matrix)
                startResizeAction.toggle()
            }
            visible: startResizeAction.checked
            onVisibleChanged: {
                targetSize = Qt.binding(() => imageView.document.imageSize)
            }
        },

        Kirigami.Action {
            visible: startResizeAction.checked
            displayComponent: Controls.ToolSeparator {
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: leftPadding
            }
        },

        Kirigami.Action {
            visible: startResizeAction.checked
            displayComponent: Controls.Label {
                text: i18nc("@title:group for crop area size spinboxes", "Size:")
            }
        },

        Kirigami.Action {
            visible: startResizeAction.checked
            displayComponent: EditorSpinBox {
                minimumContentWidth: widthTextMetrics.width
                from: 1
                to: imageView.document.imageSize.width * 8
                value: finishResizeAction.targetSize.width//selectionTool.selectionWidth / editImage.ratioX
                onValueModified: finishResizeAction.targetSize.width = value//selectionTool.selectionWidth = value * editImage.ratioX
            }
        },

        Kirigami.Action {
            visible: startResizeAction.checked
            displayComponent: EditorSpinBox {
                minimumContentWidth: heightTextMetrics.width
                from: 1
                to: imageView.document.imageSize.height * 8
                value: finishResizeAction.targetSize.height//selectionTool.selectionHeight / editImage.ratioY
                onValueModified: finishResizeAction.targetSize.height = value//selectionTool.selectionHeight = value * editImage.ratioY
            }
        },

        Kirigami.Action {
            icon.name: "image-rotate-symbolic"
            text: i18nc("@action:button Rotate an image", "Rotate")
            visible: !startResizeAction.checked

            Kirigami.Action {
                icon.name: "image-rotate-left-symbolic"
                text: i18nc("@action:button Rotate an image to the left", "Rotate Left")
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    rotateForViewer(matrix, getScale(imageView.document.transform), -90)
                    imageView.document.applyTransform(matrix)
                }
                enabled: !startResizeAction.checked
                shortcut: "Ctrl+Shift+R"
            }

            Kirigami.Action {
                icon.name: "image-rotate-right-symbolic"
                text: i18nc("@action:button Rotate an image to the right", "Rotate Right")
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    rotateForViewer(matrix, getScale(imageView.document.transform), 90)
                    imageView.document.applyTransform(matrix)
                }
                enabled: !startResizeAction.checked
                shortcut: "Ctrl+R"
            }
        },

        Kirigami.Action {
            icon.name: "image-flip-horizontal-symbolic"
            text: i18nc("@action:button Flip/mirror an image", "Flip")
            visible: !startResizeAction.checked

            Kirigami.Action {
                icon.name: "image-flip-horizontal-symbolic"
                text: i18nc("@action:button Flip/mirror an image horizontally", "Flip Horizontally")
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    scaleForViewer(matrix, getZDegrees(imageView.document.transform),
                                -1, 1)
                    imageView.document.applyTransform(matrix)
                }
                enabled: !startResizeAction.checked
            }

            Kirigami.Action {
                icon.name: "image-flip-vertical-symbolic"
                text: i18nc("@action:button Flip/mirror an image vertically", "Flip Vertically")
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    scaleForViewer(matrix, getZDegrees(imageView.document.transform),
                                1, -1)
                    imageView.document.applyTransform(matrix)
                }
                enabled: !startResizeAction.checked
            }
        },

        Kirigami.Action {
            separator: true
        },

        Kirigami.Action {
            text: i18nc("@action:button", "Undo")
            icon.name: "edit-undo-symbolic"
            enabled: imageView.document.undoStackDepth > 0
            onTriggered: imageView.document.undo()
            displayHint: Kirigami.DisplayHint.IconOnly
            shortcut: StandardKey.Undo
        },

        Kirigami.Action {
            text: i18nc("@action:button", "Redo")
            icon.name: "edit-redo-symbolic"
            enabled: imageView.document.redoStackDepth > 0
            onTriggered: imageView.document.redo()
            displayHint: Kirigami.DisplayHint.IconOnly
            shortcut: StandardKey.Redo
        },

        Kirigami.Action {
            separator: true
        },

        Kirigami.Action {
            id: saveAction
            enabled: imageView.document.modified
            text: i18nc("@action:button Save image modification", "Save")
            icon.name: "document-save-symbolic"
            onTriggered: {
                confirmSavingChangesDialog.visible = true;
            }
            shortcut: StandardKey.Save
        },

        Kirigami.Action {
            id: saveAsAction
            text: i18nc("@action:button Save As image modification", "Save As")
            icon.name: "document-save-as-symbolic"
            onTriggered: {
                saveAsDialog.open();
            }
            shortcut: StandardKey.SaveAs
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

    Koko.FileDialogHelper {
        id: saveAsDialogHelper

        selectedFile: root.imagePath
    }

    FileDialog {
        id: saveAsDialog

        fileMode: FileDialog.SaveFile
        selectedFile: root.imagePath

        nameFilters: saveAsDialogHelper.nameFilters
        selectedNameFilter.index: saveAsDialogHelper.selectedNameFilterIndex

        onAccepted: {
            const ok = imageView.document.saveImage(saveAsDialog.selectedFile.toString().replace("file://", ""));
            if (!ok) {
                msg.type = Kirigami.MessageType.Error
                msg.text = i18n("Unable to save file. Check if you have the correct permissions to save this file.")
                msg.visible = true;
                return;
            }

            // TODO: Would surely be better if imagePath was also a url
            if (root.imagePath === saveAsDialog.selectedFile) {
                root.imageEdited();
            }

            imageView.document.modified = false;
            root.imagePath = saveAsDialog.selectedFile;

            // TODO: ImageViewPage should react to imagePath changing and show that file instead
        }
    }

    ConfirmDiscardingChanges {
        id: confirmDiscardingChangesDialog

        onSaveChanges: {
            if (root.save()) {
                root.mainWindow.pageStack.layers.pop();
            }
        }

        onDiscardChanges: root.mainWindow.pageStack.layers.pop()
    }

    ConfirmSavingChanges {
        id: confirmSavingChangesDialog

        onSaveChanges: root.save();
    }

    TextMetrics {
        id: widthTextMetrics
        text: (imageView.document.imageSize.width * 10).toLocaleString(root.locale, 'f', 0)
    }

    TextMetrics {
        id: heightTextMetrics
        text: (imageView.document.imageSize.height * 10).toLocaleString(root.locale, 'f', 0)
    }

    component EditorSpinBox : Controls.SpinBox {
        id: control
        property real minimumContentWidth: 0
        contentItem: Controls.TextField {
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

    footer: Controls.ToolBar {
        contentHeight: iconTextButtonMetrics.item?.height
        contentItem: RowLayout {
            spacing: Kirigami.Units.mediumSpacing

            Loader {
                id: iconTextButtonMetrics
                visible: false
                sourceComponent: Controls.ToolButton {
                    display: Controls.AbstractButton.TextBesideIcon
                    icon.name: "edit-copy"
                    text: "metrics"
                }
            }

            AnnotationOptionsToolBarContents {
                id: annotationOptionsToolBarContents
                document: imageView.document
                visible: (imageView.document.tool.options !== KQuickImageEditor.AnnotationTool.NoOptions
                          || (imageView.document.tool.type === KQuickImageEditor.AnnotationTool.SelectTool
                              && imageView.document.selectedItem.options !== KQuickImageEditor.AnnotationTool.NoOptions))
            }

            Item {
                Layout.fillWidth: true
            }

            Controls.Label {
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
