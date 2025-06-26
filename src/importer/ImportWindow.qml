// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    ImporterHelper {
        id: importerHelper

        onErrorOccured: (error) => {
            root.showPassiveNotification(error);
        }

        onLoadingChanged: () => {
            if (!loading && isMtpWorkerAvailable) {
                root.pageStack.replace(Qt.createComponent("org.kde.koko.importer", "DevicePhotosPage"))
            }
        }
    }

    pageStack.initialPage: Kirigami.Page {
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
            icon.name: 'edit-none-symbolic'
            text: importerHelper.loading ? i18nc("@info:placeholder", "Loading") : i18nc("@info:placeholder", "Support for your camera is not installed.")
            explanation: importerHelper.loading ? '' : i18nc("@info:placeholder", "After finishing the installation process, restart the importer to continue.")
            visible: importerHelper.loading || !importerHelper.isMtpWorkerAvailable

            helpfulAction: importerHelper.loading ? null : installAction

            Kirigami.Action {
                id: installAction

                icon.name: "plasmadiscover"
                text: i18nc("@action:button", "Install Support for this Camera…")
                onTriggered: importerHelper.installKioWorker();
            }
        }
    }
}
