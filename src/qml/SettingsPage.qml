/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Layouts 1.3

import org.kde.kcm 1.2 as KCM
import org.kde.kirigami 2.12 as Kirigami

KCM.SimpleKCM {
    title: i18n("Settings")
    Kirigami.FormLayout {
        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("General:")
            text: i18n("Show preview carousel in image view")
            checked: kokoConfig.imageViewPreview
            onCheckedChanged: kokoConfig.imageViewPreview = checked
        }
        Item {
            Kirigami.FormData.isSection: true
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: i18nc("@title:group", "Slideshow settings:")
            text: i18nc("@option:check", "Loop")
            checked: kokoConfig.loopImages
            onCheckedChanged: kokoConfig.loopImages = checked
            enabled: !randomizeImagesCheckbox.checked
        }
        QQC2.CheckBox {
            id: randomizeImagesCheckbox
            text: i18nc("@option:check", "Randomize")
            checked: kokoConfig.randomizeImages
            onCheckedChanged: kokoConfig.randomizeImages = checked
        }
        QQC2.SpinBox {
            id: intervalSpinBox
            Kirigami.FormData.label: i18nc("@label:spinbox Slideshow image changing interval", "Slideshow interval:")
            from: 1
            // limited to hundreds for now because I don't want
            // to deal with regexing for locale formatted numbers
            to: 999
            value: kokoConfig.nextImageInterval
            editable: true
            textFromValue: (value) => i18ncp("Slideshow image changing interval",
                                                "1 second", "%1 seconds", value)
            valueFromText: (text) => {
                const match = text.match(/\d{1,3}/)
                return match !== null ? match[0] : intervalSpinBox.value
            }
            TextMetrics {
                id: intervalMetrics
                text: intervalSpinBox.textFromValue(intervalSpinBox.to)
            }
            wheelEnabled: true
            contentItem: QQC2.TextField {
                property int oldCursorPosition: cursorPosition
                implicitWidth: intervalMetrics.width + leftPadding + rightPadding
                implicitHeight: Math.ceil(contentHeight) + topPadding + bottomPadding
                palette: parent.palette
                leftPadding: parent.spacing
                rightPadding: parent.spacing
                topPadding: 0
                bottomPadding: 0
                font: parent.font
                color: palette.text
                selectionColor: palette.highlight
                selectedTextColor: palette.highlightedText
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                readOnly: !parent.editable
                validator: parent.validator
                inputMethodHints: parent.inputMethodHints
                selectByMouse: true
                background: null
                // Trying to mimic some of QSpinBox's behavior with suffixes
                onTextChanged: if (!inputMethodComposing) {
                    const valueText = parent.valueFromText(text).toString()
                    const valueIndex = parent.displayText.indexOf(valueText)
                    if (valueIndex >= 0) {
                        console.log(valueIndex, cursorPosition)
                        cursorPosition = Math.min(Math.max(valueIndex, oldCursorPosition), valueIndex + valueText.length)
                    }
                }
                Component.onCompleted: oldCursorPosition = cursorPosition
            }
            // Can't just use a binding because modifying the text
            // elsewhere will break bindings.
            onValueChanged: {
                contentItem.oldCursorPosition = contentItem.cursorPosition
                contentItem.text = displayText
            }
            onValueModified: kokoConfig.nextImageInterval = value
        }
    }
}
