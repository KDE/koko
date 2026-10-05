// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.purpose as Purpose
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Components

Components.ConvergentContextMenu {
    id: root

    required property var inputData
    required property string title
    required property Kirigami.ApplicationWindow application

    parent: application.Controls.Overlay.overlay

    headerContentItem: Kirigami.Heading {
        level: 2
        text: root.title
    }

    property Instantiator _instantiator: Instantiator {
        model: Purpose.PurposeAlternativesModel {
            pluginType: "Export"
            inputData: root.inputData
        }

        delegate: Kirigami.Action {
            required property int index
            required property string iconName
            required property string actionDisplay

            text: actionDisplay
            icon.name: iconName
            onTriggered: {
                const shareDialogComponent = Qt.createComponent("org.kde.koko", "ShareDialog");
                root.application.pageStack.pushDialogLayer(shareDialogComponent, {
                    title: root.title,
                    index: index,
                    model: root._instantiator.model
                })
            }
        }
        onObjectAdded: (index, object) => {
            object.index = index;
            root.actions.push(object)
        }
        onObjectRemoved: (index, object) => {
            root.actions = Array.from(root.actions).filter(obj => obj.pluginId !== object.pluginId)
        }
   }
}
