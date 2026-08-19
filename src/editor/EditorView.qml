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

    // A helper for 1D linear transformations
    QtObject {
        id: matrix1D
        // matrix[0]: scale, default: 1
        // matrix[1]: offset, default: 0
        // matrix[2]: perspective, default: 0
        // matrix[3]: divisor, default: 1
        function makeAffine(scale = 1, offset = 0): list<real> {
            return [scale, offset];
        }
        // If we wanted perspective we could make with this:
        // makePerspective(scale = 1, offset = 0, perspective = 0, divisor = 1)
        function mapValues(value: real, column0: real, column1: real): real {
            return (value * column0 + column1);
        }
        function mapValuesInverted(value: real, column0: real, column1: real): real {
            if (!Number.isFinite(column0) || column0 === 0) {
                return 0;
            }
            return ((value - column1) / column0);
        }
        function mapAffine(value: real, matrix: list<real>): real {
            return mapValues(value, matrix[0], matrix[1]);
        }
        function mapAffineInverted(value: real, matrix: list<real>): real {
            return mapValuesInverted(value, matrix[0], matrix[1]);
        }
        // If we wanted perspective we could map with these:
        // mapPerspective(value, matrix) => mapValues(value, matrix[0], matrix[1]) / mapValues(value, matrix[2], matrix[3])
        // mapPerspectiveInverted(value, matrix) => mapValuesInverted(value, matrix[2], matrix[3]) * mapValuesInverted(value, matrix[0], matrix[1]);
    }

    component PowerSlider : Controls.Slider {
        id: slider
        // The power curve. Should be greater than 0.
        required property real valuePower
        // A linear 1D matrix for mapping uncurved output values to uncurved slider values.
        // Map to a normalized range (e.g., [0,1], [-1,+1]) or else you'll have a bad curve.
        property list<real> valueMatrix: matrix1D.makeAffine()
        from: 0
        to: 1
        snapMode: Controls.Slider.SnapAlways
        function toCurved(uncurvedValue: real): real {
            if (!Number.isFinite(uncurvedValue) || uncurvedValue === 0) {
                return 0;
            }
            return Math.pow(Math.abs(uncurvedValue), 1 / valuePower) * Math.sign(uncurvedValue);
        }
        function fromCurved(curvedValue: real): real {
            if (!Number.isFinite(curvedValue) || curvedValue === 0) {
                return 0;
            }
            return Math.pow(Math.abs(curvedValue), valuePower) * Math.sign(curvedValue);
        }
        function toOutput(sliderValue: real): real {
            // uncurve, then map inversely
            return matrix1D.mapAffineInverted(fromCurved(sliderValue), valueMatrix);
        }
        function fromOutput(outputValue: real): real {
            // map, then curve
            return toCurved(matrix1D.mapAffine(outputValue, valueMatrix));
        }
    }

    component Legend : Item {
        id: legend
        required property real fromValue
        required property real midValue
        required property real toValue
        property var textFromValue: (value, locale) => {
            // -128 is QLocale::FloatingPointShortest
            return Number(value).toLocaleString(locale, 'f', -128)
        }
        property real midPos: 0.5 // normalized position within the legend
        property real spacing: Kirigami.Units.smallSpacing
        implicitWidth: fromLabel.implicitWidth
            + midLabel.implicitWidth
            + toLabel.implicitWidth
        implicitHeight: Math.max(fromLabel.implicitHeight, midLabel.implicitHeight, toLabel.implicitHeight)
        clip: width < implicitWidth
        Controls.Label {
            id: fromLabel
            anchors.left: parent.left
            height: parent.height
            text: legend.textFromValue(legend.fromValue);
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
        Controls.Label {
            id: midLabel
            anchors.left: parent.left
            anchors.leftMargin: parent.width * legend.midPos - width / 2
            height: parent.height
            text: legend.textFromValue(legend.midValue);
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        Controls.Label {
            id: toLabel
            anchors.right: parent.right
            height: parent.height
            text: legend.textFromValue(legend.toValue)
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    // This could probably be greatly simplified with DoubleSpinBox once we're
    // allowed to use Qt 6.11
    component SliderSpinBox : EditorSpinBox {
        id: spinBox
        // Floating point number string precision.
        // Should be an integer equal to or greater than 0.
        required property int displayPrecision
        // A linear 1D matrix for mapping output values to spinbox values.
        property list<real> valueMatrix: matrix1D.makeAffine()
        // A linear 1D matrix for mapping spinbox values to display values.
        property list<real> displayMatrix: matrix1D.makeAffine()
        function toOutput(spinBoxValue: int): real {
            return matrix1D.mapAffineInverted(spinBoxValue, valueMatrix);
        }
        function fromOutput(outputValue: real): int {
            return matrix1D.mapAffine(outputValue, valueMatrix);
        }
        function toDisplayValue(spinBoxValue: int): real {
            return matrix1D.mapAffine(spinBoxValue, displayMatrix);
        }
        function fromDisplayValue(displayValue: real): int {
            return matrix1D.mapAffineInverted(displayValue, displayMatrix);
        }
        function toDisplayValueString(value: int, locale = spinBox.locale): string {
            return toDisplayValue(value).toLocaleString(locale, 'f', displayPrecision);
        }
        function fromDisplayValueString(numberString: string, locale = spinBox.locale): int {
            return fromDisplayValue(Number.fromLocaleString(locale, numberString));
        }
        // SpinBox does not increment by whole steps for events from touchpads
        // and high resolution mouse wheels. I've tried using a WheelHandler to
        // allow scrolling with better behavior, but it wouldn't do anything.
        wheelEnabled: false
        textFromValue: (value, locale) => {
            return toDisplayValueString(value, locale);
        }
        valueFromText: (text, locale) => {
            return fromDisplayValueString(text, locale);
        }
        // validator: DoubleValidator {
        //     bottom: spinBox.from
        //     top: spinBox.to
        //     decimals: spinBox.displayPrecision
        //     locale: spinBox.locale.name
        //     notation: DoubleValidator.StandardNotation
        // }
        Controls.ToolTip.text: Accessible.name
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
                    function resetColorMatrix(): void {
                        imageView.colorEffect.colorMatrix = Qt.matrix4x4();
                        // reset brightness
                        brightnessSlider.brightness = Qt.binding(() => brightnessSlider.defaultBrightness);
                        // reset contrast
                        contrastSlider.contrast = Qt.binding(() => contrastSlider.defaultContrast);
                    }
                    function resetGamma(): void {
                        // reset gamma
                        imageView.colorEffect.gamma = 1;
                        gammaSlider.gamma = Qt.binding(() => gammaSlider.defaultGamma);
                    }
                    function reset(): void {
                        resetColorMatrix();
                        resetGamma();
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
                                let matrix = undefined;
                                if (brightnessSlider.valid) {
                                    matrix = imageView.colorEffect.brightnessMatrix(brightnessSlider.brightness);
                                }
                                if (contrastSlider.valid) {
                                    let contrastMatrix = imageView.colorEffect.contrastMatrix(contrastSlider.contrast);
                                    matrix = matrix === undefined ? contrastMatrix : matrix.times(contrastMatrix);
                                }
                                if (matrix !== undefined) {
                                    imageView.colorEffect.colorMatrix = matrix;
                                }
                                if (gammaSlider.valid) {
                                    imageView.colorEffect.gamma = gammaSlider.gamma;
                                }
                            }
                        }
                        Controls.Label {
                            text: i18nc("@label:slider", "Brightness:")
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        }
                        PowerSlider {
                            id: brightnessSlider
                            // brightness is always relative because it's
                            // impractical to try to track absolute brightness
                            readonly property real defaultBrightness: 0
                            readonly property bool valid: Number.isFinite(brightness) && Math.abs(brightness - defaultBrightness) > 0.00001
                            property real brightness: defaultBrightness
                            valuePower: Math.log2(10)
                            focus: true
                            Layout.fillWidth: true
                            from: fromOutput(brightnessLegend.fromValue)
                            to: fromOutput(brightnessLegend.toValue)
                            value: fromOutput(brightness)
                            stepSize: 0.01
                            onMoved: {
                                const v = Math.round(value / stepSize) * stepSize
                                brightness = toOutput(v);
                                adjustmentTimer.restart();
                            }
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            Layout.preferredWidth: Math.max(implicitWidth, 320)
                            Layout.bottomMargin: brightnessLegend.implicitHeight
                            Legend {
                                id: brightnessLegend
                                parent: brightnessSlider
                                anchors.top: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                fromValue: -1
                                midValue: 0
                                toValue: 1
                                midPos: 0.5
                                textFromValue: (value) => {
                                    const locale = brightnessSpinBox.locale;
                                    value = brightnessSpinBox.fromOutput(value);
                                    value = brightnessSpinBox.toDisplayValue(value);
                                    const text = value.toLocaleString(locale, 'f', -128) + locale.percent;
                                    return value > 0 ? '+' + text : text;
                                }
                            }
                        }
                        SliderSpinBox {
                            id: brightnessSpinBox
                            valueMatrix: matrix1D.makeAffine(100 * 1e3)
                            displayMatrix: matrix1D.makeAffine(1e-3)
                            displayPrecision: 3
                            Accessible.name: i18nc("@info:tooltip color brightness spinbox", "Brightness")
                            Layout.fillWidth: true
                            Layout.minimumWidth: Math.max(implicitWidth, leftPadding + implicitContentHeight * 2 + rightPadding)
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            from: fromOutput(brightnessLegend.fromValue)
                            to: fromOutput(brightnessLegend.toValue)
                            value: fromOutput(brightnessSlider.brightness)
                            stepSize: 1
                            textFromValue: (value, locale) => {
                                let text = brightnessSpinBox.toDisplayValueString(value);
                                return value > 0 ? '+' + text : text;
                            }
                            onValueModified: {
                                brightnessSlider.brightness = toOutput(value);
                                adjustmentTimer.restart();
                            }
                        }
                        Controls.Label {
                            text: i18nc("@label:slider", "Contrast:")
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        }
                        PowerSlider {
                            id: contrastSlider
                            // contrast is always relative because it's
                            // impractical to try to track absolute contrast
                            readonly property real defaultContrast: 1
                            readonly property bool valid: Number.isFinite(contrast) && Math.abs(contrast - defaultContrast) > 0.00001
                            property real contrast: defaultContrast
                            valueMatrix: matrix1D.makeAffine(1 / contrastLegend.toValue)
                            valuePower: Math.log2(contrastLegend.toValue)
                            Layout.fillWidth: true
                            from: fromOutput(contrastLegend.fromValue)
                            to: fromOutput(contrastLegend.toValue)
                            value: fromOutput(contrast)
                            stepSize: 0.01
                            onMoved: {
                                const v = Math.round(value / stepSize) * stepSize
                                contrast = toOutput(v);
                                adjustmentTimer.restart();
                            }
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            Layout.preferredWidth: Math.max(implicitWidth, 320)
                            Layout.bottomMargin: contrastLegend.implicitHeight
                            Legend {
                                id: contrastLegend
                                parent: contrastSlider
                                anchors.top: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                fromValue: 0
                                midValue: 1
                                toValue: 4
                                midPos: contrastSlider.fromOutput(midValue)
                                textFromValue: (value) => {
                                    const locale = contrastSpinBox.locale;
                                    value = contrastSpinBox.fromOutput(value);
                                    return contrastSpinBox.toDisplayValue(value).toLocaleString(locale, 'f', -128) + locale.percent
                                }
                            }
                        }
                        SliderSpinBox {
                            id: contrastSpinBox
                            valueMatrix: matrix1D.makeAffine(100 * 1e3)
                            displayMatrix: matrix1D.makeAffine(1e-3)
                            displayPrecision: 3
                            Accessible.name: i18nc("@info:tooltip color contrast spinbox", "Contrast")
                            Layout.fillWidth: true
                            Layout.minimumWidth: Math.max(implicitWidth, leftPadding + implicitContentHeight * 2 + rightPadding)
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            from: fromOutput(contrastLegend.fromValue)
                            to: fromOutput(contrastLegend.toValue)
                            value: fromOutput(contrastSlider.contrast)
                            stepSize: 1
                            onValueModified: {
                                contrastSlider.contrast = toOutput(value);
                                adjustmentTimer.restart();
                            }
                        }
                        Controls.Label {
                            text: i18nc("@label:slider", "Gamma:")
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        }
                        PowerSlider {
                            id: gammaSlider
                            readonly property real defaultGamma: 1
                            readonly property bool valid: Number.isFinite(gamma) && Math.abs(gamma - defaultGamma) > 0.00001 && gamma > 0.00001
                            property real gamma: defaultGamma
                            valuePower: Math.log2(gammaLegend.toValue)
                            valueMatrix: matrix1D.makeAffine(
                                1 / (gammaLegend.toValue - gammaLegend.fromValue),
                                -gammaLegend.fromValue / gammaLegend.toValue
                            )
                            Layout.fillWidth: true
                            from: fromOutput(gammaLegend.fromValue)
                            to: fromOutput(gammaLegend.toValue)
                            value: fromOutput(gamma)
                            stepSize: 0.01
                            onMoved: {
                                const v = Math.max(Math.round(value / stepSize) * stepSize, stepSize)
                                gamma = toOutput(v);
                                adjustmentTimer.restart();
                            }
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            Layout.preferredWidth: Math.max(implicitWidth, 320)
                            Layout.bottomMargin: gammaLegend.implicitHeight
                            Legend {
                                id: gammaLegend
                                parent: gammaSlider
                                anchors.top: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                fromValue: 0.25
                                midValue: 1
                                toValue: 4
                                midPos: gammaSlider.fromOutput(midValue)
                                textFromValue: (value) => {
                                    const locale = gammaSpinBox.locale;
                                    if (Math.trunc(value) === value) {
                                        // print X.0 instead of just an integer
                                        return value.toLocaleString(locale, 'f', 1);
                                    }
                                    return value.toLocaleString(locale, 'f', -128);
                                }
                            }
                        }
                        SliderSpinBox {
                            id: gammaSpinBox
                            valueMatrix: matrix1D.makeAffine(1e3)
                            displayMatrix: matrix1D.makeAffine(1e-3)
                            displayPrecision: 3
                            Accessible.name: i18nc("@info:tooltip color gamma spinbox", "Gamma")
                            Layout.fillWidth: true
                            Layout.minimumWidth: Math.max(implicitWidth, leftPadding + implicitContentHeight * 2 + rightPadding)
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            from: fromOutput(gammaLegend.fromValue)
                            to: fromOutput(gammaLegend.toValue)
                            value: fromOutput(gammaSlider.gamma)
                            stepSize: 1
                            onValueModified: {
                                gammaSlider.gamma = toOutput(value);
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
                                    // Ensure the effect doesn't disappear before
                                    // the final result is rendered.
                                    Qt.callLater(adjustPopup.reset);
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
