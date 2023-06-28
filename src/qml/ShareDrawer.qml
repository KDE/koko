// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as Controls
import org.kde.purpose 1.0 as Purpose
import org.kde.kirigami 2.14 as Kirigami

Kirigami.OverlayDrawer {
    id: drawer
    required property var inputData

    height: popupContent.implicitHeight
    edge: Qt.BottomEdge
    padding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    topPadding: 0

    property string title: i18n("Share the selected media")

    parent: applicationWindow().overlay

    ColumnLayout {
        id: popupContent
        width: parent.width
        spacing: 0

        Kirigami.ListSectionHeader {
            label: drawer.title
        }
        Repeater {
            id: listViewAction
            model: Purpose.PurposeAlternativesModel {
                pluginType: "Export"
                inputData: drawer.inputData
            }

            Kirigami.BasicListItem {
                text: model.display
                icon: model.icon.name
                onClicked: {
                    const dialog = applicationWindow().pageStack.pushDialogLayer('qrc:/qml/ShareDialog.qml', {
                        title: drawer.title,
                        index: index,
                        model: listViewAction.model
                    })
                    drawer.close()
                }
            }
        }
    }
}
