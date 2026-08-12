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
import org.kde.kirigami.actioncollection as AC
import org.kde.koko as Koko
import org.kde.kirigami as Kirigami
import org.kde.kquickimageeditor as KQuickImageEditor
import org.kde.photos.editor as PhotosEditor

pragma ComponentBehavior: Bound

Kirigami.Page {
    id: root

    required property Kirigami.ApplicationWindow mainWindow

    property url imageUrl
    readonly property string imagePath: imageUrl.toString().replace("file://", "")
    onImagePathChanged: {
        imageView.document.setBaseImage(imagePath)
    }

    readonly property string imageFileName: root.imagePath.substring(root.imagePath.lastIndexOf("/") + 1)

    property string mimeType

    signal imageEdited()

    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.ToolBar
    title: xi18nc("@title", "Edit <filename>%1</filename>", root.imageFileName)
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    function save(): bool {
        const ok = imageView.document.saveImage(imagePath);
        if (!ok) {
            root.msg.type = Kirigami.MessageType.Error
            root.msg.text = i18nc("@label", "Unable to save file. Check if you have the correct permissions to save this file.")
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

    component EditorSpinBox : Controls.SpinBox {
        id: spinBox
        stepSize: 1
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
        Binding {
            target: spinBox.contentItem
            property: "horizontalAlignment"
            value: Text.AlignRight
            restoreMode: Binding.RestoreNone
        }
    }

    actions: [
        Kirigami.Action {
            id: cropAction
            property int lastTool: imageView.document.tool.type
            AC.ActionCollection.action: "Crop"
            AC.ActionCollection.collection: "org.kde.koko.edit"
            checked: imageView.document.tool.type === KQuickImageEditor.AnnotationTool.CropTool
            onTriggered: {
                if (imageView.document.tool.type !== KQuickImageEditor.AnnotationTool.CropTool) {
                    lastTool = imageView.document.tool.type
                    imageView.document.tool.type = KQuickImageEditor.AnnotationTool.CropTool
                } else {
                    imageView.document.tool.type = lastTool
                    lastTool = Qt.binding(() => imageView.document.tool.type)
                }
            }
            displayComponent: Controls.ToolButton {
                action: cropAction
                Controls.ButtonGroup.group: annotationsToolBarContents.toolButtonGroup
            }
        },
        Kirigami.Action {
            id: resizeAction
            icon.name: "transform-scale-symbolic"
            text: i18nc("@action:button Resize an image", "Resize")
            displayComponent: Controls.ToolButton {
                id: resizeButton
                Accessible.role: Accessible.ButtonMenu
                icon.name: resizeAction.icon.name
                text: resizeAction.text
                down: resizePopup.visible || pressed
                onClicked: if (!resizePopup.visible) {
                    resizePopup.open()
                    widthSpinBox.forceActiveFocus(resizeButton.focusReason)
                }
                Controls.Popup {
                    id: resizePopup
                    property size targetSize: imageView.document.imageSize
                    onTargetSizeChanged: if (visible) {
                        resizeTimer.restart()
                    }
                    function resetToPixels(): void {
                        widthSpinBox.to = Qt.binding(() => imageView.document.imageSize.width * 10)
                        heightSpinBox.to = Qt.binding(() => imageView.document.imageSize.height * 10)
                        resizePopup.targetSize = Qt.binding(() => imageView.document.imageSize)
                        widthSpinBox.value = Qt.binding(() => resizePopup.targetSize.width)
                        widthSpinBox.contentItem.text = Qt.binding(() => widthSpinBox.displayText)
                        heightSpinBox.value = Qt.binding(() => resizePopup.targetSize.height)
                        heightSpinBox.contentItem.text = Qt.binding(() => heightSpinBox.displayText)
                    }
                    function resetToPercentage(): void {
                        widthSpinBox.to = 1000
                        heightSpinBox.to = 1000
                        resizePopup.targetSize.width = 100
                        resizePopup.targetSize.height = 100
                        widthSpinBox.value = Qt.binding(() => resizePopup.targetSize.width)
                        widthSpinBox.contentItem.text = Qt.binding(() => widthSpinBox.displayText)
                        heightSpinBox.value = Qt.binding(() => resizePopup.targetSize.height)
                        heightSpinBox.contentItem.text = Qt.binding(() => heightSpinBox.displayText)
                    }
                    Kirigami.OverlayZStacking.layer: Kirigami.OverlayZStacking.Menu
                    z: Kirigami.OverlayZStacking.z
                    y: resizeButton.height
                    clip: false
                    ColumnLayout {
                        spacing: Kirigami.Units.mediumSpacing
                        anchors.fill: parent
                        Controls.Label {
                            text: i18nc("@title:group for radio buttons to resize by type", "Resize by:")
                        }
                        Controls.ButtonGroup { buttons: radioButtonRow.children }
                        RowLayout {
                            id: radioButtonRow
                            spacing: parent.spacing
                            Layout.fillWidth: true
                            Controls.RadioButton {
                                id: pixelsRadioButton
                                Layout.fillWidth: true
                                checked: true
                                text: i18nc("@option:radio resize by pixels", "Pixels")
                                onToggled: resizePopup.resetToPixels()
                            }
                            Controls.RadioButton {
                                id: percentageRadioButton
                                Layout.fillWidth: true
                                checked: false
                                text: i18nc("@option:radio resize by percentage", "Percentage")
                                onToggled: resizePopup.resetToPercentage()
                            }
                        }
                        RowLayout {
                            spacing: parent.spacing
                            Layout.fillWidth: true
                            EditorSpinBox {
                                id: widthSpinBox
                                focus: true
                                Layout.fillWidth: true
                                Accessible.name: i18nc("@info:tooltip resize width spinbox", "Width")
                                Controls.ToolTip.text: Accessible.name
                                from: 1
                                to: imageView.document.imageSize.width * 10
                                value: resizePopup.targetSize.width
                                onValueModified: {
                                    resizePopup.targetSize.width = value
                                    if (lockAspectRatioCheckBox.checked) {
                                        resizePopup.targetSize.height = percentageRadioButton.checked
                                            ? value
                                            : value / imageView.document.imageSize.width * imageView.document.imageSize.height
                                        heightSpinBox.value = Qt.binding(() => resizePopup.targetSize.height)
                                        heightSpinBox.contentItem.text = Qt.binding(() => heightSpinBox.displayText)
                                    }
                                }
                            }
                            // Multiplication sign with more consistent appearance.
                            // The issue with using '×' (multiplication sign) or
                            // '✕' (multiplication x) is that they don't always
                            // look good in this context with different fonts.
                            // Sometimes they're too small, too big, too thick,
                            // too thin, kind of blurry or slightly off center.
                            Item {
                                Layout.fillHeight: true
                                implicitWidth: { 
                                    const w = Math.round(widthSpinBox.implicitHeight / 3)
                                    return w - w % 2 // keep it even
                                }
                                Rectangle {
                                    anchors.alignWhenCentered: false
                                    anchors.centerIn: parent
                                    rotation: 45
                                    // Get a hypotenuse to visually fill the
                                    // square bounds of the sign after rotation.
                                    height: Math.sqrt(parent.width ** 2 * 2)
                                    width: 1
                                    color: palette.windowText
                                    radius: width / 2
                                    Rectangle {
                                        anchors.alignWhenCentered: false
                                        anchors.centerIn: parent
                                        rotation: 90
                                        height: parent.height
                                        width: parent.width
                                        color: parent.color
                                        radius: parent.radius
                                    }
                                }
                            }
                            EditorSpinBox {
                                id: heightSpinBox
                                Layout.fillWidth: true
                                Accessible.name: i18nc("@info:tooltip resize height spinbox", "Height")
                                Controls.ToolTip.text: Accessible.name
                                from: 1
                                to: imageView.document.imageSize.height * 10
                                value: resizePopup.targetSize.height
                                onValueModified: {
                                    resizePopup.targetSize.height = value
                                    if (lockAspectRatioCheckBox.checked) {
                                        resizePopup.targetSize.width = percentageRadioButton.checked
                                            ? value
                                            : value / imageView.document.imageSize.height * imageView.document.imageSize.width
                                        widthSpinBox.value = Qt.binding(() => resizePopup.targetSize.width)
                                        widthSpinBox.contentItem.text = Qt.binding(() => widthSpinBox.displayText)
                                    }
                                }
                            }
                        }
                        Controls.CheckBox {
                            id: lockAspectRatioCheckBox
                            Layout.fillWidth: true
                            checked: true
                            text: i18nc("@option:check", "Keep aspect ratio")
                        }
                        Controls.Label {
                            id: originalSizeLabel
                            text: i18nc("@info", "Original file size: %1",
                                        Koko.ResizeHelper.fileSize(root.imagePath))
                        }
                        Controls.Label {
                            id: estimatedSizeLabel
                            property string fileSize: ""
                            // Avoid getting a new size in rapid succession because it can be expensive in the current implementation.
                            Timer {
                                id: resizeTimer
                                // Fast enough that it doesn't feel terribly slow.
                                // Slow enough that it won't trigger twice when my
                                // hyperscrolling mouse wheel decelerates while
                                // scrolling on the the spinboxes.
                                interval: 400
                                triggeredOnStart: true
                                onTriggered: {
                                    // trigger on start only the first time
                                    triggeredOnStart = false
                                    const usePercentage = percentageRadioButton.checked
                                    const w = usePercentage
                                        ? imageView.document.imageSize.width * resizePopup.targetSize.width / 100
                                        : resizePopup.targetSize.width
                                    const h = usePercentage
                                        ? imageView.document.imageSize.height * resizePopup.targetSize.height / 100
                                        : resizePopup.targetSize.height
                                    estimatedSizeLabel.fileSize = Koko.ResizeHelper.fileSize(imageView.document, w, h, root.mimeType)
                                }
                            }
                            text: i18nc("@info", "Estimated file size: %1", fileSize)
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight|Qt.AlignVCenter
                            spacing: parent.spacing
                            Controls.Button {
                                icon.name: "edit-undo-symbolic"
                                text: i18nc("@action:button reset size spinboxes", "Reset")
                                enabled: applyButton.enabled
                                onClicked: if (pixelsRadioButton.checked) {
                                    resizePopup.resetToPixels()
                                } else {
                                    resizePopup.resetToPercentage()
                                }
                            }
                            Controls.Button {
                                id: applyButton
                                icon.name: "dialog-ok-apply-symbolic"
                                text: i18nc("@action:button apply resize to image", "Resize")
                                enabled: percentageRadioButton.checked
                                    ? resizePopup.targetSize.width !== 100
                                        || resizePopup.targetSize.height !== 100
                                    : resizePopup.targetSize.width !== imageView.document.imageSize.width
                                        || resizePopup.targetSize.height !== imageView.document.imageSize.height
                                onClicked: {
                                    const usePercentage = percentageRadioButton.checked
                                    let matrix = Qt.matrix4x4()
                                    const xDenominator = usePercentage ? 100 : imageView.document.imageSize.width
                                    const yDenominator = usePercentage ? 100 : imageView.document.imageSize.height
                                    const sx = resizePopup.targetSize.width / xDenominator
                                    const sy = resizePopup.targetSize.height / yDenominator
                                    scaleForViewer(matrix, getZDegrees(imageView.document.transform),
                                                sx, sy)
                                    imageView.document.applyTransform(matrix)
                                    if (pixelsRadioButton.checked) {
                                        resizePopup.resetToPixels()
                                    } else {
                                        resizePopup.resetToPercentage()
                                    }
                                    resizePopup.close()
                                }
                            }
                        }
                    }
                    // contentItem.parent is the Popup's internal Page that acts
                    // as a root item and focus scope.
                    contentItem.parent.Keys.onPressed: (event) => {
                        if (!event.accepted && (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            // animate the click so the user can see the apply
                            // button was pressed.
                            applyButton.animateClick()
                            event.accepted = true
                        }
                    }
                    onAboutToShow: {
                        if (pixelsRadioButton.checked) {
                            resizePopup.resetToPixels()
                        } else {
                            resizePopup.resetToPercentage()
                        }
                        resizeTimer.restart()
                    }
                }
            }
        },

        Kirigami.Action {
            icon.name: "image-rotate-symbolic"
            text: i18nc("@action:button Rotate an image", "Rotate")

            Kirigami.Action {
                AC.ActionCollection.action: "RotateLeft"
                AC.ActionCollection.collection: "org.kde.koko.edit"
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    rotateForViewer(matrix, getScale(imageView.document.transform), -90)
                    imageView.document.applyTransform(matrix)
                }
            }

            Kirigami.Action {
                AC.ActionCollection.action: "RotateRight"
                AC.ActionCollection.collection: "org.kde.koko.edit"
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    rotateForViewer(matrix, getScale(imageView.document.transform), 90)
                    imageView.document.applyTransform(matrix)
                }
            }
        },

        Kirigami.Action {
            icon.name: "image-flip-horizontal-symbolic"
            text: i18nc("@action:button Flip/mirror an image", "Flip")

            Kirigami.Action {
                AC.ActionCollection.action: "FlipHorizontally"
                AC.ActionCollection.collection: "org.kde.koko.edit"
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    scaleForViewer(matrix, getZDegrees(imageView.document.transform),
                                -1, 1)
                    imageView.document.applyTransform(matrix)
                }
            }

            Kirigami.Action {
                AC.ActionCollection.action: "FlipVertically"
                AC.ActionCollection.collection: "org.kde.koko.edit"
                onTriggered: {
                    let matrix = Qt.matrix4x4()
                    scaleForViewer(matrix, getZDegrees(imageView.document.transform),
                                1, -1)
                    imageView.document.applyTransform(matrix)
                }
            }
        },

        Kirigami.Action {
            id: colorAdjustmentAction
            icon.name: "color-management-symbolic"
            text: i18nc("@action:button Adjust the colors of an image", "Adjust Colors")
            displayComponent: Controls.ToolButton {
                id: adjustButton
                Accessible.role: Accessible.ButtonMenu
                icon.name: colorAdjustmentAction.icon.name
                text: colorAdjustmentAction.text
                down: adjustPopup.visible || pressed
                onClicked: if (!adjustPopup.visible) {
                    adjustPopup.open()
                    gammaSlider.forceActiveFocus(adjustButton.focusReason)
                }
                Controls.Popup {
                    id: adjustPopup
                    // num must be -1 to 1
                    function invCurve(num: real): real {
                        return Math.pow(Math.abs(num), 1 / (gammaSlider.defaultGamma || 2)) * Math.sign(num);
                    }
                    // num must be -1 to 1
                    function curve(num: real): real {
                        return Math.pow(Math.abs(num), (gammaSlider.defaultGamma || 2)) * Math.sign(num);
                    }
                    function resetColorMatrix(): void {
                        imageView.colorEffect.colorMatrix = Qt.matrix4x4();
                        // reset brightness
                        brightnessSlider.brightness = Qt.binding(() => brightnessSlider.defaultBrightness);
                        // reset contrast
                        contrastSlider.contrast = Qt.binding(() => contrastSlider.defaultContrast);
                    }
                    function resetGamma(): void {
                        // reset gamma
                        imageView.colorEffect.gamma = 0;
                        gammaSlider.gamma = Qt.binding(() => gammaSlider.defaultGamma);
                    }
                    function reset(): void {
                        resetColorMatrix();
                        resetGamma();
                    }
                    Connections {
                        target: imageView.document
                        function onColorSpaceChanged(): void {
                            adjustPopup.resetGamma();
                        }
                        function onColorMatrixChanged(): void {
                            adjustPopup.resetColorMatrix();
                        }
                    }
                    Kirigami.OverlayZStacking.layer: Kirigami.OverlayZStacking.Menu
                    z: Kirigami.OverlayZStacking.z
                    y: adjustButton.height
                    x: 0
                    margins: 0
                    clip: false
                    GridLayout {
                        columns: 3
                        property real spacing: Kirigami.Units.mediumSpacing
                        rowSpacing: spacing
                        columnSpacing: spacing
                        anchors.fill: parent
                        Timer { // compress attempts to change the matrix
                            id: adjustmentTimer
                            interval: 0
                            running: false
                            repeat: false
                            onTriggered: {
                                let m = Qt.matrix4x4();
                                if (brightnessSlider.brightness !== brightnessSlider.defaultBrightness) {
                                    m = m.times(imageView.colorEffect.brightnessMatrix(brightnessSlider.brightness));
                                }
                                if (contrastSlider.contrast !== contrastSlider.defaultContrast) {
                                    m = m.times(imageView.colorEffect.contrastMatrix(contrastSlider.contrast));
                                }
                                const oldGamma = imageView.colorEffect.gamma || imageView.colorEffect.sourceColorSpace.gamma;
                                imageView.colorEffect.colorMatrix = m;
                                if (gammaSlider.gamma !== oldGamma) {
                                    imageView.colorEffect.gamma = gammaSlider.gamma;
                                }
                            }
                        }
                        Controls.Label {
                            text: i18nc("@label:slider", "Brightness:")
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        }
                        Controls.Slider {
                            id: brightnessSlider
                            // brightness is always relative because it's
                            // impractical to try to track absolute brightness
                            readonly property real defaultBrightness: 0
                            property real brightness: defaultBrightness
                            function formatNumber(num: real): string {
                                const string = Math.round(num * 100).toLocaleString(locale, 'f', 0);
                                return (num > 0 ? '+' + string : string) + locale.percent;
                            }
                            function valueForBrightness(brightness: real): real {
                                return adjustPopup.invCurve(brightness);
                            }
                            function brightnessForValue(value: real): real {
                                return adjustPopup.curve(value);
                            }
                            focus: true
                            Layout.fillWidth: true
                            from: -1
                            to: 1
                            stepSize: 0.01
                            value: valueForBrightness(brightness)
                            onMoved: {
                                brightness = brightnessForValue(value);
                                adjustmentTimer.restart();
                            }
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            Layout.preferredWidth: Math.max(implicitWidth, 320)
                            Layout.bottomMargin: brightnessRangeLabelsRow.implicitHeight
                            RowLayout {
                                id: brightnessRangeLabelsRow
                                parent: brightnessSlider
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: -implicitHeight
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: parent.spacing
                                Controls.Label {
                                    text: brightnessSlider.formatNumber(brightnessSlider.from);
                                    horizontalAlignment: Text.AlignLeft
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: brightnessSlider.formatNumber(0)
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Controls.Label {
                                    text: brightnessSlider.formatNumber(brightnessSlider.to);
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                        EditorSpinBox {
                            id: brightnessSpinBox
                            readonly property real valueScale: 100
                            enabled: brightnessSlider.enabled
                            focus: true
                            Accessible.name: i18nc("@info:tooltip color brightness spinbox", "Brightness")
                            Controls.ToolTip.text: Accessible.name
                            from: Math.round(brightnessSlider.from * valueScale)
                            to: Math.round(brightnessSlider.to * valueScale)
                            stepSize: Math.round(brightnessSlider.stepSize * valueScale)
                            value: Math.round(brightnessSlider.value * valueScale)
                            wheelEnabled: false
                            textFromValue: (value, locale) => {
                                const string = Number(brightnessSlider.brightnessForValue(value / valueScale) * valueScale).toLocaleString(locale, 'f', 2);
                                return value > 0 ? '+' + string : string;
                            }
                            valueFromText: (text, locale) => {
                                return Math.round(brightnessSlider.valueForBrightness(Number.fromLocaleString(locale, text) / valueScale) * valueScale);
                            }
                            Layout.fillWidth: true
                            Layout.minimumWidth: Math.max(implicitWidth, leftPadding + implicitContentHeight * 2 + rightPadding)
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            validator: IntValidator {
                                bottom: brightnessSpinBox.from
                                top: brightnessSpinBox.to
                            }
                            onValueModified: {
                                brightnessSlider.brightness = brightnessSlider.brightnessForValue(value / valueScale);
                                adjustmentTimer.restart();
                            }
                        }
                        Controls.Label {
                            text: i18nc("@label:slider", "Contrast:")
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        }
                        Controls.Slider {
                            id: contrastSlider
                            // contrast is always relative because it's
                            // impractical to try to track absolute contrast
                            readonly property real defaultContrast: 1
                            property real contrast: defaultContrast
                            // A scale would be more semantically appropriate,
                            // but an offset is easier to work with when the
                            // effective range is 0-2x.
                            readonly property real valueOffset: -1
                            function formatNumber(num: real): string {
                                return Math.round(num * 100).toLocaleString(locale, 'f', 0) + locale.percent;
                            }
                            function valueForContrast(contrast: real): real {
                                return adjustPopup.invCurve(contrast + contrastSlider.valueOffset)
                            }
                            function contrastForValue(value: real): real {
                                return adjustPopup.curve(value) - contrastSlider.valueOffset
                            }
                            focus: true
                            Layout.fillWidth: true
                            from: 0 + valueOffset
                            to: 2 + valueOffset
                            stepSize: 0.01
                            value: valueForContrast(contrast)
                            onMoved: {
                                contrast = contrastForValue(value);
                                adjustmentTimer.restart();
                            }
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            Layout.preferredWidth: Math.max(implicitWidth, 320)
                            Layout.bottomMargin: contrastRangeLabelsRow.implicitHeight
                            RowLayout {
                                id: contrastRangeLabelsRow
                                parent: contrastSlider
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: -implicitHeight
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: parent.spacing
                                Controls.Label {
                                    text: contrastSlider.formatNumber(contrastSlider.contrastForValue(contrastSlider.from));
                                    horizontalAlignment: Text.AlignLeft
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: contrastSlider.formatNumber((contrastSlider.contrastForValue(contrastSlider.to) + contrastSlider.contrastForValue(contrastSlider.from)) / 2);
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Controls.Label {
                                    text: contrastSlider.formatNumber(contrastSlider.contrastForValue(contrastSlider.to));
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                        EditorSpinBox {
                            id: contrastSpinBox
                            readonly property real valueScale: 100
                            enabled: contrastSlider.enabled
                            focus: true
                            Accessible.name: i18nc("@info:tooltip color contrast spinbox", "Contrast")
                            Controls.ToolTip.text: Accessible.name
                            from: Math.round(contrastSlider.from * valueScale)
                            to: Math.round(contrastSlider.to * valueScale)
                            stepSize: Math.round(contrastSlider.stepSize * valueScale)
                            value: Math.round(contrastSlider.value * valueScale)
                            wheelEnabled: false
                            textFromValue: (value, locale) => {
                                return Math.round(contrastSlider.contrastForValue(value / valueScale) * valueScale).toLocaleString(locale, 'f', 2);
                            }
                            valueFromText: (text, locale) => {
                                return Math.round(contrastSlider.valueForContrast(Number.fromLocaleString(locale, text) / valueScale) * valueScale);
                            }
                            Layout.fillWidth: true
                            Layout.minimumWidth: Math.max(implicitWidth, leftPadding + implicitContentHeight * 2 + rightPadding)
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            validator: IntValidator {
                                bottom: contrastSpinBox.from
                                top: contrastSpinBox.to
                            }
                            onValueModified: {
                                contrastSlider.contrast = contrastSlider.contrastForValue(value / valueScale);
                                adjustmentTimer.restart();
                            }
                        }
                        Controls.Label {
                            text: i18nc("@label:slider", "Gamma:")
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        }
                        Controls.Slider {
                            id: gammaSlider
                            readonly property real defaultGamma: imageView.colorEffect.sourceColorSpace.gamma
                            property real gamma: defaultGamma
                            function formatNumber(num: real): string {
                                // -128 is QLocale::FloatingPointShortest
                                return (Math.round(num * 100) / 100).toLocaleString(locale, 'f', -128);
                            }
                            focus: true
                            Layout.fillWidth: true
                            from: Math.min(0.2, defaultGamma)
                            to: Math.max(4.2, defaultGamma)
                            stepSize: 0.01
                            value: gamma
                            onMoved: {
                                gamma = value;
                                adjustmentTimer.restart();
                            }
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            Layout.preferredWidth: Math.max(implicitWidth, 320)
                            Layout.bottomMargin: gammaRangeLabelsRow.implicitHeight
                            RowLayout {
                                id: gammaRangeLabelsRow
                                parent: gammaSlider
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: -implicitHeight
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: parent.spacing
                                Controls.Label {
                                    text: gammaSlider.formatNumber(gammaSlider.from)
                                    horizontalAlignment: Text.AlignLeft
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: gammaSlider.formatNumber((gammaSlider.to + gammaSlider.from) / 2.0)
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Controls.Label {
                                    text: gammaSlider.formatNumber(gammaSlider.to)
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                        EditorSpinBox {
                            id: gammaSpinBox
                            readonly property real valueScale: 100
                            // gamma is absolute because we have a way to track
                            // absolute gamma.
                            enabled: gammaSlider.enabled
                            focus: true
                            Accessible.name: i18nc("@info:tooltip colorspace gamma spinbox", "Gamma")
                            Controls.ToolTip.text: Accessible.name
                            from: Math.round(gammaSlider.from * valueScale)
                            to: Math.round(gammaSlider.to * valueScale)
                            stepSize: Math.round(gammaSlider.stepSize * valueScale)
                            value: Math.round(gammaSlider.value * valueScale)
                            wheelEnabled: false
                            textFromValue: (value, locale) => {
                                return Number(value / valueScale).toLocaleString(locale, 'f', 2);
                            }
                            valueFromText: (text, locale) => {
                                return Math.round(Number.fromLocaleString(locale, text) * valueScale);
                            }
                            Layout.fillWidth: true
                            Layout.minimumWidth: Math.max(implicitWidth, leftPadding + implicitContentHeight * 2 + rightPadding)
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            validator: IntValidator {
                                bottom: gammaSpinBox.from
                                top: gammaSpinBox.to
                            }
                            onValueModified: {
                                gammaSlider.gamma = value / valueScale;
                                adjustmentTimer.restart();
                            }
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight|Qt.AlignVCenter
                            Layout.columnSpan: 3
                            spacing: parent.spacing
                            Controls.Button {
                                icon.name: "edit-undo-symbolic"
                                text: i18nc("@action:button reset color adjustment controls", "Reset")
                                enabled: applyAdjustmentButton.enabled
                                onClicked: adjustPopup.reset()
                            }
                            Controls.Button {
                                id: applyAdjustmentButton
                                icon.name: "dialog-ok-apply-symbolic"
                                text: i18nc("@action:button apply color adjustment to image", "Adjust")
                                enabled: brightnessSlider.brightness !== brightnessSlider.defaultBrightness || contrastSlider.contrast !== contrastSlider.defaultContrast || gammaSlider.gamma !== gammaSlider.defaultGamma
                                onClicked: {
                                    imageView.document.applyColorAdjustment(imageView.colorEffect.colorMatrix, imageView.colorEffect.gamma);
                                }
                            }
                        }
                    }
                    // contentItem.parent is the Popup's internal Page that acts
                    // as a root item and focus scope.
                    contentItem.parent.Keys.onPressed: (event) => {
                        if (!event.accepted && (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            // animate the click so the user can see the apply
                            // button was pressed.
                            applyAdjustmentButton.animateClick()
                            event.accepted = true
                        }
                    }
                }
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
        },

        Kirigami.Action {
            text: i18nc("@action:button", "Redo")
            icon.name: "edit-redo-symbolic"
            enabled: imageView.document.redoStackDepth > 0
            onTriggered: imageView.document.redo()
            displayHint: Kirigami.DisplayHint.IconOnly
        },

        Kirigami.Action {
            separator: true
        },

        Kirigami.Action {
            id: saveAction
            enabled: imageView.document.modified
            text: i18nc("@action:button Save image modification", "Save")
            icon.name: "document-save-symbolic"
            onTriggered: root.save()
            shortcut: StandardKey.Save
        },

        Kirigami.Action {
            id: saveAsAction
            text: i18nc("@action:button Save As image modification", "Save As")
            icon.name: "document-save-as-symbolic"
            onTriggered: saveAsDialog.open()
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

            showCropTool: cropAction.checked

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
        selectedFile: root.imageUrl

        nameFilters: saveAsDialogHelper.nameFilters
        selectedNameFilter.index: saveAsDialogHelper.selectedNameFilterIndex

        onAccepted: {
            const ok = imageView.document.saveImage(saveAsDialog.selectedFile.toString().replace("file://", ""));
            if (!ok) {
                msg.type = Kirigami.MessageType.Error
                msg.text = i18nc("@label", "Unable to save file. Check if you have the correct permissions to save this file.")
                msg.visible = true;
                return;
            }

            if (root.imageUrl === saveAsDialog.selectedFile) {
                root.imageEdited();
            }

            imageView.document.modified = false;
            root.imageUrl = saveAsDialog.selectedFile;

            // TODO: ImageViewPage should react to imagePath changing and show that file instead
        }
    }

    ConfirmDiscardingChanges {
        id: confirmDiscardingChangesDialog

        imageFileName: root.imageFileName

        onSaveChanges: {
            if (root.save()) {
                root.mainWindow.pageStack.layers.pop();
            }
        }

        onDiscardChanges: root.mainWindow.pageStack.layers.pop()
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
                text: i18nc("@label", "Zoom:")
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
                Controls.ToolTip.text: i18nc("@info:tooltip", "Image Zoom")
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
