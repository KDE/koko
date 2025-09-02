// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigamiaddons.components as Components

Components.MessageDialog {
    id: root

    signal saveChanges()

    title: i18n("Save")
    subtitle: i18n("Are you sure you want to save changes? The original image will be overwritten.")
    dialogType: Components.MessageDialog.Warning

    standardButtons: QQC2.Dialog.Ok |  QQC2.Dialog.Cancel

    onAccepted: {
        saveChanges();
        close();
    }

    onRejected: close()
}
