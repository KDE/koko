/* SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQml.Models 2.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.koko 0.1 as Koko

QQC2.ComboBox {
    id: comboBox
    required property Koko.Exiv2Extractor extractor

    editable: true
    model: tagsListModel

    Koko.ImageTagsModel {
        id: imageTagsModel
        onTagsChanged: if (tagsListModel.count > 0) {
            tagsListModel.clear()
            imageTagsModel.tags.forEach((element) => {
                if (!comboBox.extractor.tags.includes(element)) {
                    tagsListModel.append({ tag: element })
                }
            })
        }
    }

    // For some reason, using an array as a model directly causes the
    // contentItem to show the first item when created instead of being blank.
    ListModel {
        id: tagsListModel
        Component.onCompleted: imageTagsModel.tags.forEach((element) => {
            if (!comboBox.extractor.tags.includes(element)) {
                tagsListModel.append({ tag: element })
            }
        })
    }

    Connections {
        target: comboBox.extractor
        function onTagsChanged() {
            tagsListModel.clear()
            imageTagsModel.tags.forEach((element) => {
                if (!comboBox.extractor.tags.includes(element)) {
                    tagsListModel.append({ tag: element })
                }
            })
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
