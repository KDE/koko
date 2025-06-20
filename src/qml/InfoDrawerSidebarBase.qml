/* SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQml
import QtQuick.Window
import QtQuick.Templates as T
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.koko as Koko
import org.kde.coreaddons as KCA
import org.kde.koko.private as KokoPrivate

Flickable {
    id: flickable

    required property Koko.Exiv2Extractor extractor
    required property Koko.PhotosApplication application

    implicitWidth: column.implicitWidth + leftMargin + rightMargin
    implicitHeight: contentHeight + topMargin + bottomMargin

    contentWidth: width - leftMargin - rightMargin
    contentHeight: column.implicitHeight

    leftMargin: Kirigami.Units.largeSpacing
    rightMargin: Kirigami.Units.largeSpacing
    topMargin: Kirigami.Units.largeSpacing
    bottomMargin: Kirigami.Units.largeSpacing

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    pixelAligned: true

    Kirigami.WheelHandler { target: flickable }

    ColumnLayout {
        id: column

        property real availableWidth: width - leftPadding - rightPadding

        spacing: Kirigami.Units.smallSpacing
        width: parent.width

        FormCard.FormTextDelegate {
            text: i18nc("@label", "File name:")
            description: flickable.extractor.simplifiedPath
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
        }

        FormCard.FormTextDelegate {
            text: i18nc("@label", "Dimension:")
            description: i18nc("dimensions", "%1 x %2", flickable.extractor.width, flickable.extractor.height)
            visible: flickable.extractor.width > 0 && flickable.extractor.height > 0
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
        }

        FormCard.FormTextDelegate {
            text: i18nc("@label", "Size:")
            visible: flickable.extractor.size !== 0
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
            description: KCA.Format.formatByteSize(flickable.extractor.size, 2)
        }

        FormCard.FormTextDelegate {
            visible: flickable.extractor.time.length > 0
            text: i18nc("@label", "Created:")
            description: flickable.extractor.time
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
        }

        FormCard.FormTextDelegate {
            visible: flickable.extractor.model.length > 0
            text: i18nc("@label", "Model:")
            description: flickable.extractor.model
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
        }

        FormCard.FormTextDelegate {
            text: i18nc("@label", "Latitude:")
            visible: flickable.extractor.gpsLatitude !== 0
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
            description: flickable.extractor.gpsLatitude
        }

        FormCard.FormTextDelegate {
            text: i18nc("@label", "Longitude:")
            visible: flickable.extractor.gpsLongitude !== 0
            description: flickable.extractor.gpsLongitude
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
        }

        FormCard.AbstractFormDelegate {
            id: ratingDelegate

            text: i18nc("@label", "Rating:")
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
            background: null

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    text: ratingDelegate.text
                }

                Row {
                    // stars look disconnected with higher spacing
                    spacing: Kirigami.Settings.isMobile ? Kirigami.Units.smallSpacing : Math.round(Kirigami.Units.smallSpacing / 4)
                    Accessible.role: Accessible.List
                    Accessible.name: i18n("Current rating %1", flickable.extractor.rating)
                    Layout.fillWidth: true
                    Repeater {
                        model: [ 1, 3, 5, 7, 9 ]
                        QQC2.AbstractButton {
                            activeFocusOnTab: true
                            width: height
                            height: Kirigami.Units.iconSizes.smallMedium
                            text: i18n("Set rating to %1", ratingTo)
                            property int ratingTo: {
                                if (flickable.extractor.rating == modelData + 1) {
                                    return modelData
                                } else if (flickable.extractor.rating == modelData) {
                                    return modelData - 1
                                } else {
                                    return modelData + 1
                                }
                            }
                            contentItem: Kirigami.Icon {
                                source: flickable.extractor.rating > modelData ? "rating" :
                                        flickable.extractor.rating < modelData ? "rating-unrated" : "rating-half"
                                width: parent.width
                                height: parent.height
                                color: (parent.focusReason == Qt.TabFocusReason || parent.focusReason == Qt.BacktabFocusReason) && parent.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            }
                            onClicked: {
                                flickable.extractor.rating = ratingTo
                            }
                        }
                    }
                }
            }
        }

        FormCard.FormTextAreaDelegate {
            id: imageDescription

            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
            label: i18nc("@label", "Description:")
            text: flickable.extractor.description
            placeholderText: i18n("Image description…")
            KeyNavigation.priority: KeyNavigation.BeforeItem
            Keys.onTabPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
            onEditingFinished: {
                flickable.extractor.description = text
            }
        }

        FormCard.AbstractFormDelegate {
            id: tagsDelegate

            text: i18nc("@label", "Tags:")
            horizontalPadding: Kirigami.Units.smallSpacing
            verticalPadding: Kirigami.Units.smallSpacing
            background: null

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    text: tagsDelegate.text
                }

                RowLayout {
                    id: tagInputLayout
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true
                    TagInput {
                        id: tagInput
                        Layout.fillWidth: true
                        extractor: flickable.extractor
                        application: flickable.application
                    }
                    QQC2.Button {
                        enabled: tagInput.editText
                        display: QQC2.AbstractButton.IconOnly
                        icon.name: "list-add"
                        text: i18n("Add Tag")
                        onClicked: tagInput.accepted()
                    }
                }

                Flow {
                    Layout.preferredWidth: tagInputLayout.implicitWidth
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    Repeater {
                        model: flickable.extractor.tags
                        Kirigami.Chip {
                            text: modelData
                            onRemoved: {
                                const index = flickable.extractor.tags.indexOf(modelData)
                                if (index > -1) {
                                    flickable.extractor.tags.splice(index, 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
