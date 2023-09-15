/* SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Window 2.15
import QtQuick.Templates 2.15 as T
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.koko 0.1 as Koko
import org.kde.coreaddons 1.0 as KCA
import org.kde.koko.private 0.1 as KokoPrivate

Flickable {
    id: flickable
    required property Koko.Exiv2Extractor extractor
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
        focus: true
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            topPadding: Kirigami.Units.smallSpacing
            text: i18n("File Name")
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: flickable.extractor.simplifiedPath
            wrapMode: Text.Wrap
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Dimension")
            topPadding: Kirigami.Units.smallSpacing
            visible: flickable.extractor.width > 0 && flickable.extractor.height > 0
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: i18nc("dimensions", "%1 x %2", flickable.extractor.width, flickable.extractor.height)
            visible: flickable.extractor.width > 0 && flickable.extractor.height > 0
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Size")
            topPadding: Kirigami.Units.smallSpacing
            visible: flickable.extractor.size !== 0
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: KCA.Format.formatByteSize(flickable.extractor.size, 2)
            visible: flickable.extractor.size !== 0
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Created")
            topPadding: Kirigami.Units.smallSpacing
            visible: flickable.extractor.time.length > 0
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: flickable.extractor.time
            visible: flickable.extractor.time.length > 0
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Model")
            topPadding: Kirigami.Units.smallSpacing
            visible: flickable.extractor.model.length > 0
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: flickable.extractor.model
            visible: flickable.extractor.model.length > 0
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Latitude")
            topPadding: Kirigami.Units.smallSpacing
            visible: flickable.extractor.gpsLatitude !== 0
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: flickable.extractor.gpsLatitude
            visible: flickable.extractor.gpsLatitude !== 0
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Longitude")
            topPadding: Kirigami.Units.smallSpacing
            visible: flickable.extractor.gpsLongitude !== 0
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: flickable.extractor.gpsLongitude
            visible: flickable.extractor.gpsLongitude !== 0
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Rating")
            topPadding: Kirigami.Units.smallSpacing
        }
        Row {
            // stars look disconnected with higher spacing
            spacing: Kirigami.Settings.isMobile ? Kirigami.Units.smallSpacing : Math.round(Kirigami.Units.smallSpacing / 4)
            Accessible.role: Accessible.List
            Accessible.name: i18n("Current rating %1", flickable.extractor.rating)
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
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Description")
            topPadding: Kirigami.Units.smallSpacing
        }
        QQC2.TextArea {
            id: imageDescription
            text: flickable.extractor.description
            Layout.fillWidth: true
            verticalAlignment: Qt.AlignTop
            placeholderText: i18n("Image description…")
            KeyNavigation.priority: KeyNavigation.BeforeItem
            Keys.onTabPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
            onEditingFinished: {
                flickable.extractor.description = text
            }
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: i18n("Tags")
            topPadding: Kirigami.Units.smallSpacing
        }
        RowLayout {
            id: tagInputLayout
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
            TagInput {
                id: tagInput
                Layout.fillWidth: true
                extractor: flickable.extractor
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
