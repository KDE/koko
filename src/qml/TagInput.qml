/* SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQml.Models
import org.kde.kirigami as Kirigami
import org.kde.koko as Koko

QQC2.ComboBox {
    id: comboBox

    required property Koko.Exiv2Extractor extractor
    required property Koko.PhotosApplication application

    editable: true
    model: tagsListModel

    Connections {
        target: root.application

        function onTagsChanged(): void {
            if (tagsListModel.count > 0) {
                tagsListModel.clear();
                comboBox.application.tags.forEach((element) => {
                    if (!comboBox.extractor.tags.includes(element.text)) {
                        tagsListModel.append({ tag: element.text });
                    }
                });
            }
        }
    }

    // For some reason, using an array as a model directly causes the
    // contentItem to show the first item when created instead of being blank.
    ListModel {
        id: tagsListModel
        Component.onCompleted: comboBox.application.tags.forEach((element) => {
            if (!comboBox.extractor.tags.includes(element.text)) {
                tagsListModel.append({ tag: element.text })
            }
        })
    }

    Connections {
        target: comboBox.extractor
        function onTagsChanged(): void {
            tagsListModel.clear()
            comboBox.application.tags.forEach((element) => {
                if (!comboBox.extractor.tags.includes(element.text)) {
                    tagsListModel.append({ tag: element.text });
                }
            });
        }
    }

    QQC2.Label {
        id: placeholder
        x: comboBox.contentItem.x + comboBox.contentItem.leftPadding
        y: comboBox.contentItem.y + comboBox.contentItem.topPadding
        width: comboBox.contentItem.width - comboBox.contentItem.leftPadding - comboBox.contentItem.rightPadding
        height: comboBox.contentItem.height - comboBox.contentItem.topPadding - comboBox.contentItem.bottomPadding
        text: i18n("Add new tag…")
        font: comboBox.font
        opacity: 0.5
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        visible: !comboBox.editText
        elide: Text.ElideRight
    }

    onAccepted: {
        const text = comboBox.editText.trim()
        if (text.length > 0) {
            comboBox.extractor.tags.push(text)
        }
        comboBox.editText = ""
    }
}
