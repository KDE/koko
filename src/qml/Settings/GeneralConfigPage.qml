// SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import org.kde.koko as Koko

Kirigami.ScrollablePage {
    id: root

    Kirigami.Form {
        Kirigami.FormGroup {
            Kirigami.FormEntry {
                title: i18nc("@label:slider", "Thumbnail size:")

                contentItem: QQC2.Slider {
                    id: thumbnailSizeSlider
                    Layout.fillWidth: true

                    from: 80
                    to: 256
                    stepSize: 16
                    value: Koko.Config.iconSize
                    snapMode: QQC2.Slider.SnapAlways
                    onMoved: {
                        Koko.Config.iconSize = value;
                        Koko.Config.save();
                    }

                    QQC2.ToolTip {
                        parent: thumbnailSizeSlider.handle
                        delay: 0
                        visible: thumbnailSizeSlider.pressed
                        text: i18nc("@info:tooltip, %1 is a size in pixels", "%1 px", thumbnailSizeSlider.value)
                    }
                }
            }
        }

        Kirigami.FormGroup {
            Koko.ColorScheme {}
        }

        Kirigami.FormGroup {
            title: i18nc("@title:group", "File types")

            QQC2.ButtonGroup {
                id: mediaTypesGroup
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:check", "Images and videos")
                    QQC2.ButtonGroup.group: mediaTypesGroup
                    checked: Koko.Config.mediaTypes === Koko.Config.ImagesAndVideos
                    enabled: !Koko.Config.isMediaTypesImmutable
                    onToggled: {
                        Koko.Config.mediaTypes = Koko.Config.ImagesAndVideos;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:check", "Images only")
                    QQC2.ButtonGroup.group: mediaTypesGroup
                    checked: Koko.Config.mediaTypes === Koko.Config.ImagesOnly
                    enabled: !Koko.Config.isMediaTypesImmutable
                    onToggled: {
                        Koko.Config.mediaTypes = Koko.Config.ImagesOnly;
                        Koko.Config.save();
                    }
                }
            }
        }

        Kirigami.FormGroup {
            title: i18nc("@title:group", "Gallery Sorting")

            QQC2.ButtonGroup {
                id: sortBehaviorGroup
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:radio As in, sorting mode", "Natural sorting")
                    QQC2.ButtonGroup.group: sortBehaviorGroup
                    checked: Koko.Config.sortBehavior === Koko.Config.Natural
                    enabled: !Koko.Config.isSortBehavorImmutable
                    onToggled: {
                        Koko.Config.sortBehavior = Koko.Config.Natural;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:radio As in, sorting mode", "Alphabetical (case insensitive)")
                    QQC2.ButtonGroup.group: sortBehaviorGroup
                    checked: Koko.Config.sortBehavior === Koko.Config.AlphabeticalCaseInsensitive
                    enabled: !Koko.Config.isSortBehavorImmutable
                    onToggled: {
                        Koko.Config.sortBehavior = Koko.Config.AlphabeticalCaseInsensitive;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:radio As in, sorting mode", "Alphabetical (case sensitive)")
                    QQC2.ButtonGroup.group: sortBehaviorGroup
                    checked: Koko.Config.sortBehavior === Koko.Config.AlphabeticalCaseSensitive
                    enabled: !Koko.Config.isSortBehavorImmutable
                    onToggled: {
                        Koko.Config.sortBehavior = Koko.Config.AlphabeticalCaseSensitive;
                        Koko.Config.save();
                    }
                }
            }
        }

        Kirigami.FormGroup {
            title: i18nc("@title:group", "Image Background")

            QQC2.ButtonGroup {
                id: imageViewBackgroundColorGroup
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:radio As in, background color", "Black")
                    QQC2.ButtonGroup.group: imageViewBackgroundColorGroup
                    checked: Koko.Config.imageViewBackgroundColor === Koko.Config.Black
                    enabled: !Koko.Config.isImageViewBackgroundColorImmutable
                    onToggled: {
                        Koko.Config.imageViewBackgroundColor = Koko.Config.Black;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:radio As in, background color", "Gray")
                    QQC2.ButtonGroup.group: imageViewBackgroundColorGroup
                    checked: Koko.Config.imageViewBackgroundColor === Koko.Config.Gray
                    enabled: !Koko.Config.isImageViewBackgroundColorImmutable
                    onToggled: {
                        Koko.Config.imageViewBackgroundColor = Koko.Config.Gray;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormEntry {
                contentItem: QQC2.RadioButton {
                    text: i18nc("@option:radio As in, background color", "White")
                    QQC2.ButtonGroup.group: imageViewBackgroundColorGroup
                    checked: Koko.Config.imageViewBackgroundColor === Koko.Config.White
                    enabled: !Koko.Config.isImageViewBackgroundColorImmutable
                    onToggled: {
                        Koko.Config.imageViewBackgroundColor = Koko.Config.White;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormEntry {
                subtitle: i18nc("info", "Use the background color specified by the theme")

                contentItem: QQC2.RadioButton {
                    id: imageViewBackgroundColorThemeDefaultDelegate
                    text: i18nc("@option:radio As in, background color", "Theme default")
                    QQC2.ButtonGroup.group: imageViewBackgroundColorGroup
                    checked: Koko.Config.imageViewBackgroundColor === Koko.Config.Theme
                    enabled: !Koko.Config.isImageViewBackgroundColorImmutable
                    onToggled: {
                        Koko.Config.imageViewBackgroundColor = Koko.Config.Theme;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormSeparator {}

            Kirigami.FormEntry {
                contentItem: QQC2.CheckBox {
                    id: imageViewShowCheckerboardDelegate
                    text: i18nc("@option:check", "Show a checkerboard behind transparent images")
                    checked: Koko.Config.imageViewShowCheckerboard
                    enabled: !Koko.Config.isImageViewShowCheckerboardImmutable
                    onToggled: {
                        Koko.Config.imageViewShowCheckerboard = checked;
                        Koko.Config.save();
                    }
                }
            }
        }

        Kirigami.FormGroup {
            title: i18nc("@title:group", "Image View")

            Kirigami.FormEntry {
                contentItem: QQC2.CheckBox {
                    id: enlargeSmallImagesDelegate
                    text: i18nc("@option:check", "Enlarge images that are smaller than the viewport")
                    checked: Koko.Config.enlargeSmallImages
                    enabled: !Koko.Config.isEnlargeSmallImagesImmutable
                    onToggled: {
                        Koko.Config.enlargeSmallImages = checked;
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormEntry {
                contentItem: QQC2.CheckBox {
                    id: rememberZoomDelegate
                    text: i18nc("@option:check", "Remember zoom level when switching between images")
                    checked: Koko.Config.rememberZoom
                    enabled: !Koko.Config.isRememberZoomImmutable
                    onToggled: {
                        Koko.Config.rememberZoom = checked;
                        Koko.Config.save();
                    }
                }
            }
        }

        Kirigami.FormGroup {
            title: i18nc("@title:group", "Slideshow")
            visible: !Kirigami.Settings.isMobile

            Kirigami.FormEntry {
                contentItem: QQC2.CheckBox {
                    id: randomizeImagesCheckbox
                    text: i18nc("@option:check", "Randomize")
                    checked: Koko.Config.randomizeImages
                    onCheckedChanged: {
                        Koko.Config.randomizeImages = checked
                        Koko.Config.save();
                    }
                }
            }

            Kirigami.FormSeparator {}

            Kirigami.FormEntry {
                title: i18nc("@label:spinbox Slideshow image changing interval", "Slideshow interval:")

                contentItem: QQC2.SpinBox {
                    id: intervalSpinBox
                    from: 1
                    // limited to hundreds for now because I don't want
                    // to deal with regexing for locale formatted numbers
                    to: 999
                    value: Koko.Config.nextImageInterval
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
                        palette: intervalSpinBox.palette
                        leftPadding: intervalSpinBox.spacing
                        rightPadding: intervalSpinBox.spacing
                        topPadding: 0
                        bottomPadding: 0
                        font: intervalSpinBox.font
                        color: palette.text
                        selectionColor: palette.highlight
                        selectedTextColor: palette.highlightedText
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        readOnly: !intervalSpinBox.editable
                        validator: intervalSpinBox.validator
                        inputMethodHints: intervalSpinBox.inputMethodHints
                        selectByMouse: true
                        background: null
                        // Trying to mimic some of QSpinBox's behavior with suffixes
                        onTextChanged: if (!inputMethodComposing) {
                            const valueText = intervalSpinBox.valueFromText(text).toString()
                            const valueIndex = intervalSpinBox.displayText.indexOf(valueText)
                            if (valueIndex >= 0) {
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
                    onValueModified: {
                        Koko.Config.nextImageInterval = value
                        Koko.Config.save();
                    }
                }
            }
        }
    }
}
