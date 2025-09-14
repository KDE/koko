// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.purpose as Purpose
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

Kirigami.OverlayDrawer {
    id: drawer

    required property var inputData

    height: popupContent.implicitHeight
    edge: Qt.BottomEdge

    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    topPadding: 0

    property string title: i18nc("@title:menu", "Share")

    parent: drawer.Controls.Overlay.overlay

    ColumnLayout {
        id: popupContent
        width: parent.width
        spacing: 0

        Kirigami.ListSectionHeader {
            text: drawer.title
        }

        Repeater {
            id: listViewAction
            model: Purpose.PurposeAlternativesModel {
                pluginType: "Export"
                inputData: drawer.inputData
            }

            FormCard.FormButtonDelegate {
                required property int index
                required property string iconName
                required property string actionDisplay

                text: actionDisplay
                icon.name: iconName
                onClicked: {
                    const shareDialogComponent = Qt.createComponent("org.kde.koko", "ShareDialog");
                    const dialog = (drawer.Controls.ApplicationWindow.window as Kirigami.ApplicationWindow).pageStack.pushDialogLayer(shareDialogComponent, {
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
