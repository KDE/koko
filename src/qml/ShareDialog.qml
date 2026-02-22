/*
 * SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls as Controls
import org.kde.purpose as Purpose
import org.kde.kirigami as Kirigami

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
        onTriggered: window.Kirigami.PageStack.closeDialog()
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
            window.Kirigami.PageStack.closeDialog()
        }
    }
}
