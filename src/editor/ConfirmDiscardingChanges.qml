// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigamiaddons.components as Components

Components.MessageDialog {
    id: root

    signal saveChanges()
    signal discardChanges()

    title: i18n("Discard changes")
    subtitle: i18n("This image has been modified. Do you want to save your changes or discard them?")
    dialogType: Components.MessageDialog.Warning

    standardButtons: QQC2.Dialog.Save | QQC2.Dialog.Discard | QQC2.Dialog.Cancel

    onAccepted: {
        saveChanges();
        close();
    }

    onDiscarded: {
        discardChanges();
        close();
    }

    onRejected: close()
}
