/*
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15 as Controls
import org.kde.purpose 1.0 as Purpose
import org.kde.kirigami 2.14 as Kirigami

Kirigami.Page {
    id: window

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    property alias index: jobView.index
    property alias model: jobView.model

    Controls.Action {
        shortcut: 'Escape'
        onTriggered: window.closeDialog()
    }

    Component.onCompleted: jobView.start()

    contentItem: Purpose.JobView {
        id: jobView
        onStateChanged: {
            if (state === Purpose.PurposeJobController.Finished) {
                if (jobView.job.output.url !== "") {
                    // Show share url
                    const resultUrl = jobView.job.output.url;
                    notificationManager.showNotification(true, resultUrl);
                    clipboard.content = resultUrl;
                }
            } else if (state === Purpose.PurposeJobController.Error) {
                // Show failure notification
                notificationManager.showNotification(false, jobView.job.errorString);
            } else if (state === Purpose.PurposeJobController.Cancelled) {
                // Do nothing
            }
            window.closeDialog()
        }
    }
}
