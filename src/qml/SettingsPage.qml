/*
 * SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

import QtQuick 2.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Dialogs 1.0
import QtQuick.Layouts 1.3

import org.kde.kirigami 2.12 as Kirigami

Kirigami.Page {
    title: i18n("Settings")

    ColumnLayout {
        spacing: 0
        anchors.fill: parent

        QQC2.Label {
            text: i18n("Pictures paths:")
        }

        FileScanningConfiguration {
            id: fileScanningConfiguration
            Kirigami.FormData.label: i18n("Picture folder locations:")
            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.topMargin: 10
            Layout.leftMargin: 20
            Layout.rightMargin: 10
        }

        QQC2.Button {
            text: i18n("Save")
            onClicked: {
                kokoConfig.save()
                pageStack.pop()
            }
        }
    }
}
