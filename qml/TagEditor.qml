/*
 * Copyright (C) 2014 Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.gallery 0.1 as Gallery

ColumnLayout {
    PlasmaExtras.Heading {
        text: "Tags"
        level: 2
        font.bold: true
    }
    PlasmaComponents.TextField {
        id: input
        placeholderText: "Add Tag"
        clearButtonShown: true
        Layout.fillWidth: true

        onAccepted: {
            tagModel.addTag(input.text);
            input.text = "";
        }
    }

    ListView {
        id: listView
        height: 500
        Layout.fillWidth: true

        delegate: Tag {
            property variant theModel: model
            text: model.display
            color: model.color
            width: view.width

            onTagRemoved: {
                console.log("Remove me!!");
                listView.model.removeRows(model.index, 1)
            }
        }

        model: Gallery.TagModel {
            id: tagModel
            tags: ["Fire", "Flower", "Hunger"]
        }
    }
}
