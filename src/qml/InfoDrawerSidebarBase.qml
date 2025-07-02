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

        Repeater {
            model: ExivFilterModel {
                sourceModel: flickable.extractor
            }

            delegate: FormCard.FormTextDelegate {
                required property string label
                required property string displayName

                text: i18nc("@label %1 is a translated title e.g. 'Date Created'", "%1:", label)
                description: displayName
                horizontalPadding: Kirigami.Units.smallSpacing
                verticalPadding: Kirigami.Units.smallSpacing
            }
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

                // NOTE: This could be made generic and shared where other apps want a good ratings control
                Item {
                    implicitHeight: ratingRow.height
                    implicitWidth: ratingRow.width

                    Row {
                        id: ratingRow

                        readonly property int size: Kirigami.Units.iconSizes.smallMedium

                        // stars look disconnected with higher spacing
                        spacing: Kirigami.Settings.isMobile ? Kirigami.Units.smallSpacing : Math.round(Kirigami.Units.smallSpacing / 4)

                        Accessible.role: Accessible.List
                        Accessible.name: i18n("Current rating %1", flickable.extractor.rating)
                        Layout.fillWidth: true

                        Repeater {
                            model: [ 1, 3, 5, 7, 9 ]
                            // NOTE: Despite MouseArea handling clicking, ratings must
                            // still be AbstractButton to allow for keyboard interaction
                            delegate: QQC2.AbstractButton {
                                readonly property int midRating: modelData
                                readonly property int ratingTo: {
                                    if (flickable.extractor.rating == midRating + 1) {
                                        return midRating
                                    } else if (flickable.extractor.rating == midRating) {
                                        return midRating - 1
                                    } else {
                                        return midRating + 1
                                    }
                                }

                                activeFocusOnTab: true
                                width: ratingRow.size
                                height: ratingRow.size
                                text: i18n("Set rating to %1", ratingTo)

                                contentItem: Kirigami.Icon {
                                    source: {
                                        if (flickable.extractor.rating > midRating) {
                                            return "rating";
                                        } else if (flickable.extractor.rating < midRating) {
                                            return "rating-unrated";
                                        } else {
                                            return Qt.application.layoutDirection === Qt.LeftToRight ? "rating-half" : "rating-half-rtl";
                                        }
                                    }
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

                    // Handle dragging and clicking between rating buttons
                    MouseArea {
                        anchors.fill: parent

                        // Only recognise a drag when we move this distance
                        readonly property int minimumDragDistance: 2

                        property int pressX: 0
                        property int pressY: 0
                        property bool isDrag: false

                        function closestRatingItem(x: int, y: int): Item {
                            let bestDistance = Number.MAX_VALUE;
                            let best = null;

                            for (let i = 0; i < ratingRow.children.length; ++i) {
                                let child = ratingRow.children[i];
                                if (child instanceof QQC2.AbstractButton) {
                                    let dx = x - (child.x + (child.width / 2));
                                    let dy = y - (child.y + (child.height / 2));

                                    let distanceToCenter = Math.hypot(dx, dy);
                                    if (distanceToCenter < bestDistance) {
                                        bestDistance = distanceToCenter;
                                        best = child;
                                    }
                                }
                            }

                            return best;
                        }

                        onPressed: (mouse) => {
                            // Store x,y such that we can recognise a drag when we move far enough
                            pressX = mouse.x;
                            pressY = mouse.y;
                            isDrag = false;
                        }
                        onPositionChanged: (mouse) => {
                            if (!isDrag) {
                                // Don't start dragging until the mouse moves just a little bit
                                isDrag = Math.hypot(mouse.x - pressX, mouse.y - pressY) >= minimumDragDistance;
                            } else {
                                let item = closestRatingItem(mouse.x, mouse.y);
                                if (item) {
                                    let localX = mouse.x - item.x;
                                    let third = item.width / 3;
                                    let reversed = (Qt.application.layoutDirection === Qt.RightToLeft);

                                    let newRating;
                                    if (localX < third) {
                                        newRating = (reversed ? item.midRating + 1 : item.midRating - 1);
                                    } else if (localX > (item.width - third)) {
                                        newRating = (reversed ? item.midRating - 1 : item.midRating + 1);
                                    } else {
                                        newRating = item.midRating;
                                    }

                                    if (flickable.extractor.rating !== newRating) {
                                        flickable.extractor.rating = newRating;
                                    }
                                }
                            }
                        }
                        onClicked: (mouse) => {
                            // Only handle click when we aren't dragging
                            if (!isDrag) {
                                closestRatingItem(mouse.x, mouse.y)?.clicked();
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

        QQC2.Button {
            Layout.fillWidth: true
            icon.name: 'view-list-details-symbolic'
            text: i18nc("@action:button", "Choose What's Shown")
            onClicked: QQC2.ApplicationWindow.window.pageStack.pushDialogLayer(Qt.createComponent("org.kde.koko", "ImageMetadataPage"), {
                extractor: flickable.extractor,
            }, {
                width: Kirigami.Units.gridUnit * 20,
            });
        }
    }
}
