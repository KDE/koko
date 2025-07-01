// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigamiaddons.components as Components

Components.MessageDialog {
    id: root

    signal discardChanges()

    title: i18n("Discard changes")

    dialogType: Components.MessageDialog.Warning

    QQC2.Label {
        text: i18n("Are you sure you want to discard all changes?")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    standardButtons: QQC2.Dialog.Cancel | QQC2.Dialog.Ok

    onRejected: close();
    onAccepted: {
        discardChanges();
        close();
    }
}
