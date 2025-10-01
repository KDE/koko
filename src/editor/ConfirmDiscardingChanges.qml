// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

Kirigami.PromptDialog {
    id: root

    signal saveChanges()
    signal discardChanges()

    title: i18n("Unsaved Changes")
    subtitle: i18n("This image has been modified. Do you want to save your changes or discard them?")
    dialogType: Kirigami.PromptDialog.Warning

    standardButtons: Kirigami.Dialog.Save | Kirigami.Dialog.Discard | Kirigami.Dialog.Cancel

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
