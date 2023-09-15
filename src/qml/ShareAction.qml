// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQml.Models
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2 as Controls
import org.kde.purpose 1 as Purpose
import org.kde.kirigami 2 as Kirigami

/**
 * Action that allows an user to share data with other apps and service
 * installed on their computer. The goal of this high level API is to
 * adapte itself for each platform and adopt the native component.
 *
 * TODO add more doc, before moving to Peruse upstream
 *
 * TODO add Android support
 */
Kirigami.Action {
    id: shareAction
    icon.name: "emblem-shared-symbolic"
    text: i18n("Share")
    tooltip: i18n("Share the selected media")

    /**
     * This property holds the input data for purpose.
     *
     * @code{.qml}
     * Purpose.ShareAction {
     *     inputData: {
     *         'urls': ['file://home/notroot/Pictures/mypicture.png'],
     *         'mimeType': ['image/png']
     *     }
     * }
     * @endcode
     */
    property var inputData: ({})

    onTriggered: {
        if (!Kirigami.Settings.isMobile) {
            return;
        }
        const shareDrawerComponent = Qt.createComponent('qrc:/qml/ShareDrawer.qml');
        const drawer = shareDrawerComponent.createObject(applicationWindow().overlay, {
            inputData: shareAction.inputData,
            title: shareAction.text
        });
        drawer.open();
    }

    property Instantiator _instantiator: Instantiator {
        active: !Kirigami.Settings.isMobile
        model: Purpose.PurposeAlternativesModel {
            pluginType: "Export"
            inputData: shareAction.inputData
        }

        delegate: Kirigami.Action {
            property int index
            text: model.display
            icon.name: model.iconName
            onTriggered: {
                applicationWindow().pageStack.pushDialogLayer('qrc:/qml/ShareDialog.qml', {
                    title: shareAction.tooltip,
                    index: index,
                    model: shareAction._instantiator.model
                })
            }
        }
        onObjectAdded: (index, object) => {
            object.index = index;
            shareAction.children.push(object)
        }
        onObjectRemoved: (index, object) => {
            shareAction.children = Array.from(shareAction.children).filter(obj => obj.pluginId !== object.pluginId)
        }
    }
}
