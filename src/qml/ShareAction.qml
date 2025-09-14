// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import org.kde.purpose as Purpose
import org.kde.kirigami as Kirigami

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

    text: i18nc("@action Share an image/video", "&Share")
    icon.name: "emblem-shared-symbolic"

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
        const shareDrawerComponent = Qt.createComponent("org.kde.koko", "ShareDrawer");
        const drawer = shareDrawerComponent.createObject(applicationWindow().overlay, {
            inputData: shareAction.inputData
        }) as ShareDrawer;
        drawer.open();
    }

    property Instantiator _instantiator: Instantiator {
        active: !Kirigami.Settings.isMobile
        model: Purpose.PurposeAlternativesModel {
            pluginType: "Export"
            inputData: shareAction.inputData
        }

        delegate: Kirigami.Action {
            required property int index
            required property string iconName
            required property string actionDisplay

            text: actionDisplay
            icon.name: iconName
            onTriggered: {
                const shareDialogComponent = Qt.createComponent("org.kde.koko", "ShareDialog");
                applicationWindow().pageStack.pushDialogLayer(shareDialogComponent, {
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
