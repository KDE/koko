/* SPDX-FileCopyrightText: 2022 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Templates as T
import Qt.labs.platform
import org.kde.kirigami as Kirigami
import org.kde.kquickimageeditor

Row {
    id: root

    required property AnnotationDocument document
    readonly property AnnotationTool tool: document.tool
    readonly property SelectedItemWrapper selectedItem: document.selectedItem

    readonly property bool useSelectionOptions: tool.type === AnnotationTool.SelectTool || (tool.type === AnnotationTool.TextTool && selectedItem.options & AnnotationTool.TextOption)
    readonly property int options: useSelectionOptions ? selectedItem.options : tool.options
    property int displayMode: Controls.AbstractButton.TextBesideIcon
    property int focusPolicy: Qt.StrongFocus
    readonly property bool mirrored: effectiveLayoutDirection === Qt.RightToLeft

    clip: childrenRect.width > width || childrenRect.height > height
    spacing: Kirigami.Units.mediumSpacing

    Timer {
        id: commitChangesTimer
        interval: 250
        onTriggered: root.selectedItem.commitChanges()
    }

    Connections {
        target: root.document
        function onSelectedItemWrapperChanged(): void {
            commitChangesTimer.stop()
        }
    }

    component ToolButton: Controls.ToolButton {
        focusPolicy: root.focusPolicy
        display: root.displayMode

        Controls.ToolTip.text: text
        Controls.ToolTip.visible: (hovered || pressed) && display === Controls.ToolButton.IconOnly
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    component SpinBox : Controls.SpinBox {
        id: spinBox
        anchors.verticalCenter: parent.verticalCenter
        stepSize: 1
        property real minimumContentWidth: 0
        contentItem: Controls.TextField {
            id: textField
            implicitWidth: Math.max(Math.ceil(contentWidth), spinBox.minimumContentWidth) + leftPadding + rightPadding
            implicitHeight: Math.ceil(contentHeight) + topPadding + bottomPadding
            palette: spinBox.palette
            leftPadding: spinBox.spacing
            rightPadding: spinBox.spacing
            topPadding: 0
            bottomPadding: 0
            text: spinBox.displayText
            font: spinBox.font
            color: Kirigami.Theme.textColor
            selectionColor: Kirigami.Theme.highlightColor
            selectedTextColor: Kirigami.Theme.highlightedTextColor
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            readOnly: !spinBox.editable
            validator: spinBox.validator
            inputMethodHints: spinBox.inputMethodHints
            selectByMouse: true
            background: null
        }
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
        Binding {
            target: spinBox.contentItem
            property: "horizontalAlignment"
            value: Text.AlignRight
            restoreMode: Binding.RestoreNone
        }
    }

    TextMetrics {
        id: widthTextMetrics
        text: (imageView.document.imageSize.width * 10).toLocaleString(root.locale, 'f', 0)
    }

    TextMetrics {
        id: heightTextMetrics
        text: (imageView.document.imageSize.height * 10).toLocaleString(root.locale, 'f', 0)
    }

    component AspectRatioComboBox : Controls.ComboBox {
        id: aspectRatioComboBox
        function parseAspectRatio(text: string): real {
            const numbers = text.split(":")
            // parseFloat turns undefined into NaN.
            const ratio = parseFloat(numbers[0])/parseFloat(numbers[1])
            return ratio // can return NaN, which is falsy
        }
        // https://stackoverflow.com/a/71164857
        function toRational(x: real): var {
            var m  = Math.floor(x),
                x_ = 1/(x-m),
                p_ = 1,
                q_ = 0,
                p  = m,
                q  = 1;
            if (x === m) return {n:p,d:q};
            while (Math.abs(x - p/q) > Number.EPSILON){
                m  = Math.floor(x_);
                x_ = 1/(x_-m);
                [p_, q_, p, q] = [p, q, m*p+p_, m*q+q_];
            }
            return isNaN(x) ? NaN : {n:p,d:q};
        }
        editable: true
        textRole: "text"
        valueRole: "ratio"
        model: [
            {text: i18nc("@item:inlistbox aspect ratio", "Unlocked"), ratio: 0},
            {text: i18nc("@item:inlistbox aspect ratio", "Current Image"), ratio: root.document.canvasRect.width/root.document.canvasRect.height},
            {text: i18nc("@item:inlistbox aspect ratio", "Square"), ratio: 1},
            {text: i18nc("@item:inlistbox aspect ratio", "This Screen"), ratio: Screen.width/Screen.height},
            {text: i18nc("@item:inlistbox aspect ratio", "16:9"), ratio: 16/9},
            {text: i18nc("@item:inlistbox aspect ratio", "7:5"), ratio: 7/5},
            {text: i18nc("@item:inlistbox aspect ratio", "3:2"), ratio: 3/2},
            {text: i18nc("@item:inlistbox aspect ratio", "4:3"), ratio: 4/3},
            {text: i18nc("@item:inlistbox aspect ratio", "5:4"), ratio: 5/4},
            {text: i18nc("@item:inlistbox aspect ratio", "ISO Paper (Landscape)"), ratio: Math.SQRT2},
            {text: i18nc("@item:inlistbox aspect ratio", "US Letter (Landscape)"), ratio: 11/8.5},
            {text: i18nc("@item:inlistbox aspect ratio", "9:16"), ratio: 9/16},
            {text: i18nc("@item:inlistbox aspect ratio", "5:7"), ratio: 5/7},
            {text: i18nc("@item:inlistbox aspect ratio", "2:3"), ratio: 2/3},
            {text: i18nc("@item:inlistbox aspect ratio", "3:4"), ratio: 3/4},
            {text: i18nc("@item:inlistbox aspect ratio", "4:5"), ratio: 4/5},
            {text: i18nc("@item:inlistbox aspect ratio", "ISO Paper (Portrait)"), ratio: Math.SQRT1_2},
            {text: i18nc("@item:inlistbox aspect ratio", "US Letter (Portrait)"), ratio: 8.5/11}
        ]
        Text {
            readonly property Item contentItem: aspectRatioComboBox.contentItem
            parent: aspectRatioComboBox
            x: parent.leftPadding
            y: parent.topPadding
            width: parent.availableWidth
            height: parent.availableHeight

            text: i18nc("@item:inlistbox aspect ratio placeholder", "Width:Height")
            font: parent.font
            color: parent.palette.placeholderText
            LayoutMirroring.enabled: false
            horizontalAlignment: contentItem?.effectiveHorizontalAlignment ?? (parent.mirrored ? Text.AlignRight : Text.AlignLeft)
            verticalAlignment: contentItem?.verticalAlignment ?? Text.AlignVCenter
            visible: aspectRatioComboBox.editText === "" && (!contentItem.activeFocus || horizontalAlignment !== Text.AlignHCenter)
            elide: Text.ElideRight
        }
        // The order in which text changed signals are emitted and
        // currentIndex/currentText/currentValue changed signals are
        // emitted makes it so we have to parse the text first to react
        // in a timely manner to user input. We fall back to model values
        // when parsed text does not give a number.
        onEditTextChanged: {
            const value = parseAspectRatio(editText) || valueAt(currentIndex)
            root.tool.aspectRatio = value
            if (value && indexOfValue(value) < 0 && !contentItem.activeFocus) {
                const fraction = toRational(root.tool.aspectRatio)
                editText = `${fraction.n}:${fraction.d}`
            }
        }
        Component.onCompleted: {
            const ratio = root.tool.aspectRatio
            currentIndex = indexOfValue(ratio)
            if (ratio && currentIndex < 0) {
                const fraction = toRational(ratio)
                editText = `${fraction.n}:${fraction.d}`
            }
        }
    }

    Loader { // stroke
        id: strokeLoader
        anchors.verticalCenter: parent.verticalCenter
        visible: active
        active: root.options & AnnotationTool.StrokeOption
        sourceComponent: Row {
            spacing: root.spacing

            Controls.CheckBox {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label, annotation tool option", "Stroke:")
                checked: colorRect.color.a > 0
                onToggled: if (root.useSelectionOptions) {
                    root.selectedItem.strokeColor.a = checked
                } else {
                    root.tool.strokeColor.a = checked
                }
            }

            Controls.SpinBox {
                id: spinBox
                function setStrokeWidth() {
                    if (root.useSelectionOptions && root.selectedItem.strokeWidth !== spinBox.value) {
                        root.selectedItem.strokeWidth = spinBox.value
                        commitChangesTimer.restart()
                    } else {
                        root.tool.strokeWidth = spinBox.value
                    }
                }
                anchors.verticalCenter: parent.verticalCenter
                from: fillLoader.active ? 0 : 1
                to: 99
                stepSize: 1
                value: root.useSelectionOptions ? root.selectedItem.strokeWidth : root.tool.strokeWidth
                textFromValue: (value, locale) => {
                    // we don't use the locale here because the px suffix
                    // needs to be treated as a translatable string, which
                    // doesn't take into account the locale passed in here.
                    // but it's going to be the application locale
                    // which ki18n uses so it doesn't matter that much
                    // unless someone decides to set the locale for a specific
                    // part of spectacle in the future.
                    return i18ncp("px: pixels", "%1px", "%1px", Math.round(value))
                }
                valueFromText: (text, locale) => {
                    return Number.fromLocaleString(locale, text.replace(/\D/g,''))
                }
                Controls.ToolTip.text: i18nc("@label, annotation tool option", "Stroke Width")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                // not using onValueModified because of https://bugreports.qt.io/browse/QTBUG-91281
                /* When we change the value of the control, we set the corresponding property in the
                 * annotation tool or selected annotation (if we have a selected annotation).
                 * If we have a selected annotation, we then restart a timer to commit the change as
                 * a new undoable item.
                 * We delay the call for doing the things above to prevent the property in the
                 * selected annotation from being set to the control's value before the control's
                 * value is set to the value from the selected annotation when changing selected
                 * annotations.
                 * If we don't do this, the property for a selected annotation can be unintentionally
                 * set to the value from the previous selected action.
                 * In the initial patch porting to Qt Quick, I originally used a Binding object with
                 * `delayed: true`, but that actually didn't prevent the issue. For some reason,
                 * using callLater in a signal handler did, so that's what I went with.
                 */
                onValueChanged: Qt.callLater(setStrokeWidth)
                Binding {
                    target: spinBox.contentItem
                    property: "horizontalAlignment"
                    value: Text.AlignRight
                    restoreMode: Binding.RestoreNone
                }
            }

            ToolButton {
                anchors.verticalCenter: parent.verticalCenter
                display: Controls.ToolButton.IconOnly
                Controls.ToolTip.text: i18nc("@label, annotation tool option", "Stroke Color")
                Rectangle { // should we use some kind of image provider instead?
                    id: colorRect
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit
                    height: Kirigami.Units.gridUnit
                    radius: height / 2
                    color: root.useSelectionOptions ? root.selectedItem.strokeColor : root.tool.strokeColor
                    border.color: Qt.rgba(parent.palette.windowText.r,
                                          parent.palette.windowText.g,
                                          parent.palette.windowText.b, 0.5)
                    border.width: 1
                }
                onClicked: {
                    const component = Qt.createComponent("Qt.labs.platform", "ColorDialog");
                    const dialog = component.createObject(root);
                    dialog.currentColor = root.useSelectionOptions ? root.selectedItem.strokeColor : root.tool.strokeColor;
                    dialog.accepted.connect(() => {
                        if (root.tool.type == AnnotationTool.SelectTool) {
                            root.selectedItem.strokeColor = dialog.color;
                            root.selectedItem.commitChanges();
                        } else if (root.tool.type == AnnotationTool.TextTool && root.selectedItem.options & AnnotationTool.TextOption) {
                            root.tool.strokeColor = dialog.color;
                            root.selectedItem.strokeColor = dialog.color;
                            root.selectedItem.commitChanges();
                        } else {
                            root.tool.strokeColor = dialog.color;
                        }
                    });

                    dialog.open();
                }
            }
        }
    }

    Controls.ToolSeparator {
        anchors.verticalCenter: parent.verticalCenter
        visible: strokeLoader.visible && (root.options & ~AnnotationTool.StrokeOption) > AnnotationTool.StrokeOption
    }

    Loader { // fill
        id: fillLoader
        anchors.verticalCenter: parent.verticalCenter
        visible: active
        active: root.options & AnnotationTool.FillOption
        sourceComponent: Row {
            spacing: root.spacing

            Controls.CheckBox {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label, annotation tool option", "Fill:")
                checked: colorRect.color.a > 0
                onToggled: if (root.useSelectionOptions) {
                    root.selectedItem.fillColor.a = checked
                } else {
                    root.tool.fillColor.a = checked
                }
            }

            ToolButton {
                anchors.verticalCenter: parent.verticalCenter
                display: Controls.ToolButton.IconOnly
                Controls.ToolTip.text: i18nc("@label", "Fill Color")
                Rectangle {
                    id: colorRect
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit
                    height: Kirigami.Units.gridUnit
                    radius: height / 2
                    color: root.useSelectionOptions ? root.selectedItem.fillColor : root.tool.fillColor
                    border.color: Qt.rgba(parent.palette.windowText.r,
                                          parent.palette.windowText.g,
                                          parent.palette.windowText.b, 0.5)
                    border.width: 1
                }
                onClicked: {
                    const component = Qt.createComponent("Qt.labs.platform", "ColorDialog");
                    const dialog = component.createObject(root);
                    dialog.currentColor = root.useSelectionOptions ? root.selectedItem.fillColor : root.tool.fillColor;
                    dialog.accepted.connect(() => {
                        if (root.tool.type == AnnotationTool.SelectTool) {
                            root.selectedItem.fillColor = dialog.currentColor;
                            root.selectedItem.commitChanges();
                        } else if (root.tool.type == AnnotationTool.TextTool && root.selectedItem.options & AnnotationTool.TextOption) {
                            root.tool.fillColor = dialog.currentColor;
                            root.selectedItem.fillColor = dialog.currentColor;
                            root.selectedItem.commitChanges();
                        } else {
                            root.tool.fillColor = dialog.currentColor;
                        }
                    });

                    dialog.open();
                }
            }
        }
    }

    Controls.ToolSeparator {
        anchors.verticalCenter: parent.verticalCenter
        visible: fillLoader.visible && (root.options & ~AnnotationTool.FillOption) > AnnotationTool.FillOption
    }

    Loader { // strength
        id: strengthLoader
        anchors.verticalCenter: parent.verticalCenter
        visible: active
        active: root.options & AnnotationTool.StrengthOption
        sourceComponent: Row {
            spacing: root.spacing
            leftPadding: spacing
            rightPadding: spacing

            Controls.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label:slider Strength of annotation tool effect", "Strength:")
            }

            Controls.Slider {
                id: slider
                readonly property real strength: root.useSelectionOptions ? root.selectedItem.strength : root.tool.strength
                anchors.verticalCenter: parent.verticalCenter
                function setStrength() {
                    if (root.useSelectionOptions && root.selectedItem.strength !== slider.value) {
                        root.selectedItem.strength = slider.value
                        commitChangesTimer.restart()
                    } else {
                        root.tool.strength = slider.value
                    }
                }
                from: 0
                to: 1
                value: strength
                Controls.ToolTip.text: i18nc("@info:tooltip", "The strength of the effect.")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                onMoved: setStrength()
            }
        }
    }

    Controls.ToolSeparator {
        anchors.verticalCenter: parent.verticalCenter
        visible: strengthLoader.visible && (root.options & ~AnnotationTool.StrengthOption) > AnnotationTool.StrengthOption
    }

    Loader { // font
        id: fontLoader
        anchors.verticalCenter: parent.verticalCenter
        visible: active
        active: root.options & AnnotationTool.FontOption
        sourceComponent: Row {
            spacing: root.spacing

            Controls.Label {
                leftPadding: root.mirrored ? 0 : parent.spacing
                rightPadding: root.mirrored ? parent.spacing : 0
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label", "Font:")
            }

            ToolButton {
                anchors.verticalCenter: parent.verticalCenter
                display: Controls.ToolButton.TextOnly
                contentItem: Controls.Label {
                    readonly property font currentFont: root.useSelectionOptions ? root.selectedItem.font : root.tool.font
                    leftPadding: Kirigami.Units.mediumSpacing
                    rightPadding: leftPadding
                    font.family: currentFont.family
                    font.styleName: currentFont.styleName
                    text: font.styleName !== "" ?
                        i18ncp("%2 font family, %3 font style name, %1 font point size", "%2 %3 %1pt", "%2 %3 %1pts", currentFont.pointSize, font.family, font.styleName) :
                        i18ncp("%2 font family %1 font point size", "%2 %1pt", "%2 %1pts", currentFont.pointSize, font.family)
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    const component = Qt.createComponent("Qt.labs.platform", "FontDialog");
                    const dialog = component.createObject(root);
                    dialog.accepted.connect(() => {
                        const newFont = dialog.font
                        // Copied from stripRegularStyleName() in KFontChooserDialog.
                        // For more details see:
                        // https://bugreports.qt.io/browse/QTBUG-63792
                        // https://bugs.kde.org/show_bug.cgi?id=378523
                        if (newFont.weight == Font.Normal
                            && (newFont.styleName === "Regular"
                                || newFont.styleName === "Normal"
                                || newFont.styleName === "Book"
                                || newFont.styleName === "Roman")) {
                            newFont.styleName = "";
                        }

                        if (root.tool.type == AnnotationTool.SelectTool) {
                            root.selectedItem.font = newFont;
                            root.selectedItem.commitChanges();
                        } else if (root.tool.type == AnnotationTool.TextTool && root.selectedItem.options & AnnotationTool.TextOption) {
                            root.tool.font = newFont;
                            root.selectedItem.font = newFont;
                            root.selectedItem.commitChanges();
                        } else {
                            root.tool.font = newFont;
                        }
                    });

                    dialog.open();

                    // Setting after opening to ensure the previous font is pre-selected
                    dialog.currentFont = root.useSelectionOptions ? root.selectedItem.font : root.tool.font;
                }
            }

            ToolButton {
                anchors.verticalCenter: parent.verticalCenter
                display: Controls.ToolButton.IconOnly
                Controls.ToolTip.text: i18nc("@label", "Font Color")
                Rectangle {
                    id: colorRect
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit
                    height: Kirigami.Units.gridUnit
                    radius: height / 2
                    color: root.useSelectionOptions ? root.selectedItem.fontColor : root.tool.fontColor
                    border.color: Qt.rgba(parent.palette.windowText.r,
                                          parent.palette.windowText.g,
                                          parent.palette.windowText.b, 0.5)
                    border.width: 1
                }
                onClicked: {
                    const component = Qt.createComponent("Qt.labs.platform", "ColorDialog");
                    const dialog = component.createObject(root);
                    dialog.currentColor = root.useSelectionOptions ? root.selectedItem.fontColor : root.tool.fontColor;
                    dialog.accepted.connect(() => {
                        if (root.tool.type == AnnotationTool.SelectTool) {
                            root.selectedItem.fontColor = dialog.color;
                            root.selectedItem.commitChanges();
                        } else if (root.tool.type == AnnotationTool.TextTool && root.selectedItem.options & AnnotationTool.TextOption) {
                            root.tool.fontColor = dialog.color;
                            root.selectedItem.fontColor = dialog.color;
                            root.selectedItem.commitChanges();
                        } else {
                            root.tool.fontColor = dialog.color;
                        }
                    });

                    dialog.open();
                }
            }
        }
    }

    Controls.ToolSeparator {
        anchors.verticalCenter: parent.verticalCenter
        visible: fontLoader.visible && (root.options & ~AnnotationTool.FontOption) > AnnotationTool.FontOption
    }

    Loader { // number
        id: numberLoader
        anchors.verticalCenter: parent.verticalCenter
        visible: active
        active: root.options & AnnotationTool.NumberOption
        sourceComponent: Row {
            spacing: root.spacing

            Controls.Label {
                leftPadding: root.mirrored ? 0 : parent.spacing
                rightPadding: root.mirrored ? parent.spacing : 0
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label, annotation tool option", "Number:")
            }

            Controls.SpinBox {
                id: spinBox
                readonly property int number: root.useSelectionOptions ? root.selectedItem.number : root.tool.number
                anchors.verticalCenter: parent.verticalCenter
                function setNumber() {
                    if (root.useSelectionOptions && root.selectedItem.number !== spinBox.value) {
                        root.selectedItem.number = spinBox.value
                        commitChangesTimer.restart()
                    } else {
                        root.tool.number = spinBox.value
                    }
                }
                from: -99
                to: Math.max(999, number + 1)
                stepSize: 1
                value: number
                Controls.ToolTip.text: i18nc("@info:tooltip", "Number for number annotations")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.delay: Kirigami.Units.toolTipDelay
                // not using onValueModified because of https://bugreports.qt.io/browse/QTBUG-91281
                onValueChanged: Qt.callLater(setNumber)
                Binding {
                    target: spinBox.contentItem
                    property: "horizontalAlignment"
                    value: Text.AlignRight
                    restoreMode: Binding.RestoreNone
                }
            }
        }
    }

    Controls.ToolSeparator {
        anchors.verticalCenter: parent.verticalCenter
        visible: numberLoader.visible && (root.options & ~AnnotationTool.NumberOption) > AnnotationTool.NumberOption
    }

    Controls.CheckBox {
        id: shadowCheckBox
        anchors.verticalCenter: parent.verticalCenter
        visible: root.options & AnnotationTool.ShadowOption
        text: i18nc("@label, annotation tool option", "Shadow")
        checked: {
            if (root.tool.type === AnnotationTool.TextTool && root.selectedItem.options & AnnotationTool.TextOption) {
                return root.tool.shadow;
            } else if (root.useSelectionOptions) {
                return root.selectedItem.shadow;
            } else {
                return root.tool.shadow;
            }
        }
        onToggled: {
            let changed = false
            if (root.tool.type === AnnotationTool.TextTool && root.selectedItem.options & AnnotationTool.TextOption) {
                changed = root.selectedItem.shadow !== checked
                root.selectedItem.shadow = checked;
                root.tool.shadow = checked;
            } else if (root.useSelectionOptions) {
                changed = root.selectedItem.shadow !== checked
                root.selectedItem.shadow = checked;
            } else {
                root.tool.shadow = checked;
            }
            if (changed) {
                commitChangesTimer.restart();
            }
        }
    }

    Loader { // crop
        id: cropLoader
        anchors.verticalCenter: parent.verticalCenter
        visible: active
        active: root.tool.type === AnnotationTool.CropTool
        sourceComponent: Row {
            spacing: root.spacing

            Controls.Label {
                leftPadding: root.mirrored ? 0 : parent.spacing
                rightPadding: root.mirrored ? parent.spacing : 0
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label crop area position", "Position:")
            }

            SpinBox {
                from: 0
                to: widthSpinBox.to - widthSpinBox.from
                value: Math.abs(root.tool.geometry.x * root.document.imageDpr)
                Controls.ToolTip.text: i18nc("@info:tooltip", "Crop area X position")
                onValueModified: {
                    const absX = value / root.document.imageDpr
                    const absY = Math.abs(root.tool.geometry.y)
                    const absW = Math.abs(root.tool.geometry.width)
                    const absH = Math.abs(root.tool.geometry.height)
                    root.tool.geometry.x = absX
                    root.tool.geometry.y = absY
                    root.tool.geometry.width = absW
                    root.tool.geometry.height = absH
                }
            }
            SpinBox {
                from: 0
                to: heightSpinBox.to - heightSpinBox.from
                value: Math.abs(root.tool.geometry.y * root.document.imageDpr)
                Controls.ToolTip.text: i18nc("@info:tooltip", "Crop area Y position")
                onValueModified: {
                    const absX = Math.abs(root.tool.geometry.x)
                    const absY = value / root.document.imageDpr
                    const absW = Math.abs(root.tool.geometry.width)
                    const absH = Math.abs(root.tool.geometry.height)
                    root.tool.geometry.x = absX
                    root.tool.geometry.y = absY
                    root.tool.geometry.width = absW
                    root.tool.geometry.height = absH
                }
            }

            Controls.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label crop area size", "Size:")
            }

            SpinBox {
                id: widthSpinBox
                from: root.tool.geometry.width === 0 ? 0 : 1
                to: root.document.canvasRect.width * 10 * root.document.imageDpr
                value: Math.abs(root.tool.geometry.width * root.document.imageDpr)
                Controls.ToolTip.text: i18nc("@info:tooltip", "Crop area width")
                onValueModified: {
                    const absX = Math.abs(root.tool.geometry.x)
                    const absY = Math.abs(root.tool.geometry.y)
                    const absW = value / root.document.imageDpr
                    const absH = Math.abs(root.tool.geometry.height)
                    root.tool.geometry.x = absX
                    root.tool.geometry.y = absY
                    root.tool.geometry.width = absW
                    root.tool.geometry.height = absH
                }
            }
            SpinBox {
                id: heightSpinBox
                from: root.tool.geometry.height === 0 ? 0 : 1
                to: root.document.canvasRect.height * 10 * root.document.imageDpr
                value: Math.abs(root.tool.geometry.height * root.document.imageDpr)
                Controls.ToolTip.text: i18nc("@info:tooltip", "Crop area height")
                onValueModified: {
                    const absX = Math.abs(root.tool.geometry.x)
                    const absY = Math.abs(root.tool.geometry.y)
                    const absW = Math.abs(root.tool.geometry.width)
                    const absH = value / root.document.imageDpr
                    root.tool.geometry.x = absX
                    root.tool.geometry.y = absY
                    root.tool.geometry.width = absW
                    root.tool.geometry.height = absH
                }
            }

            Controls.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label", "Aspect Ratio:")
            }

            AspectRatioComboBox {
                id: cropAspectRatioComboBox
            }

            ToolButton {
                icon.name: "edit-undo"
                text: i18nc("@action reset selection", "Reset")
                onClicked: {
                    root.tool.geometry = undefined
                    root.tool.aspectRatio = undefined
                    cropAspectRatioComboBox.currentIndex = 0
                }
            }

            ToolButton {
                icon.name: "dialog-ok"
                text: i18nc("@action accept selection", "Accept")
                onClicked: {
                    root.document.cropCanvas(root.tool.geometry)
                    root.tool.geometry = undefined
                }
            }
        }
    }

    Loader { // resize
        id: resizeLoader
        anchors.verticalCenter: parent.verticalCenter
        visible: active
        active: root.tool.type === AnnotationTool.ResizeTool
        sourceComponent: Row {
            spacing: root.spacing

            Controls.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label crop area size", "Size:")
            }

            SpinBox {
                id: widthSpinBox
                minimumContentWidth: widthTextMetrics.width
                from: root.tool.geometry.width === 0 ? 0 : 1
                to: root.document.canvasRect.width * 10 * root.document.imageDpr
                value: Math.abs(root.tool.geometry.width * root.document.imageDpr)
                Controls.ToolTip.text: i18nc("@info:tooltip", "Resize area width")
                onValueModified: {
                    const absX = Math.abs(root.tool.geometry.x)
                    const absY = Math.abs(root.tool.geometry.y)
                    const absW = value / root.document.imageDpr
                    const absH = Math.abs(root.tool.geometry.height)
                    root.tool.geometry.x = absX
                    root.tool.geometry.y = absY
                    root.tool.geometry.width = absW
                    root.tool.geometry.height = absH
                }
            }
            SpinBox {
                id: heightSpinBox
                minimumContentWidth: heightTextMetrics.width
                from: root.tool.geometry.height === 0 ? 0 : 1
                to: root.document.canvasRect.height * 10 * root.document.imageDpr
                value: Math.abs(root.tool.geometry.height * root.document.imageDpr)
                Controls.ToolTip.text: i18nc("@info:tooltip", "Resize area height")
                onValueModified: {
                    const absX = Math.abs(root.tool.geometry.x)
                    const absY = Math.abs(root.tool.geometry.y)
                    const absW = Math.abs(root.tool.geometry.width)
                    const absH = value / root.document.imageDpr
                    root.tool.geometry.x = absX
                    root.tool.geometry.y = absY
                    root.tool.geometry.width = absW
                    root.tool.geometry.height = absH
                }
            }

            Controls.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: i18nc("@label", "Aspect Ratio:")
            }

            AspectRatioComboBox {
                id: resizeAspectRatioComboBox
            }

            ToolButton {
                icon.name: "edit-undo"
                text: i18nc("@action reset selection", "Reset")
                onClicked: {
                    root.tool.geometry = undefined
                    root.tool.aspectRatio = undefined
                    resizeAspectRatioComboBox.currentIndex = 0
                }
            }

            ToolButton {
                icon.name: "dialog-ok"
                text: i18nc("@action accept selection", "Accept")
                enabled: root.tool.geometry.width !== 0 && root.tool.geometry.height !== 0
                onClicked: {
                    let matrix = Qt.matrix4x4()
                    const sx = root.tool.geometry.width / root.document.imageSize.width
                    const sy = root.tool.geometry.height / root.document.imageSize.height
                    const zDegrees = Math.atan2(matrix.m21, matrix.m11) // in radians
                                   * (180 / Math.PI) // to degrees
                    const rotationAxes = Qt.vector3d(0, 0, 1)
                    matrix.rotate(-zDegrees, rotationAxes)
                    matrix.scale(sx, sy, 1)
                    matrix.rotate(zDegrees, rotationAxes)
                    root.document.applyTransform(matrix)
                    root.tool.geometry = undefined
                }
            }
        }
    }
}
