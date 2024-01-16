// SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.18 as Kirigami
import QtQuick.Layouts 1.15
import org.kde.kirigamiaddons.formcard 1.0 as FormCard

Kirigami.PageRow {
    id: settingsPage

    globalToolBar.style: Kirigami.ApplicationHeaderStyle.ToolBar

    initialPage: FormCard.FormCardPage {
        title: i18nc("@title:window", "Settings")

        FormCard.FormHeader {
            title: i18n("General")
        }

        FormCard.FormCard {
            FormCard.AbstractFormDelegate {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    QQC2.Label {
                        text: i18n("Thumbnails size:")
                        Layout.fillWidth: true
                    }
                    QQC2.Slider {
                        Layout.fillWidth: true
                        from: Kirigami.Units.gridUnit * 4
                        to: Kirigami.Units.gridUnit * 8
                        value: kokoConfig.iconSize
                        onMoved: kokoConfig.iconSize = value;
                    }
                }
            }
        }

        FormCard.FormHeader {
            title: i18nc("@title:group", "Slideshow settings:")
            visible: !Kirigami.Settings.isMobile
        }

        FormCard.FormCard {
            visible: !Kirigami.Settings.isMobile
            FormCard.FormCheckDelegate {
                id: randomizeImagesCheckbox
                text: i18nc("@option:check", "Randomize")
                checked: kokoConfig.randomizeImages
                onCheckedChanged: kokoConfig.randomizeImages = checked
            }

            FormCard.FormDelegateSeparator { above: randomizeImagesCheckbox}

            FormCard.AbstractFormDelegate {
                Layout.fillWidth: true
                background: Item {}
                contentItem: RowLayout {
                    QQC2.Label {
                        text: i18nc("@label:spinbox Slideshow image changing interval", "Slideshow interval:")
                        Layout.fillWidth: true
                    }
                    QQC2.SpinBox {
                        id: intervalSpinBox
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
        }

        FormCard.FormCard {
            Layout.topMargin: Kirigami.Units.gridUnit
            FormCard.FormButtonDelegate {
                text: i18n("About Koko")
                onClicked: pageStack.layers.push(Qt.resolvedUrl("AboutPage.qml"));

                Component {
                    id: aboutPage
                    FormCard.AboutPage {
                        aboutData: About
                    }
                }
            }
        }
    }
}
