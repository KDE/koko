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
            if (!loading && isMtpWorkerAvailable && imageDirectory.toString().length > 0) {
                root.pageStack.replace(Qt.createComponent("org.kde.koko.importer", "DevicePhotosPage"), {
                    url: importerHelper.imageDirectory,
                })
            }
        }
    }

    pageStack.initialPage: Kirigami.Page {
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
            icon.name: 'edit-none-symbolic'
            text: if (importerHelper.loading) {
                return i18nc("@info:placeholder", "Loading");
            } else if (importerHelper.imageDirectory.toString().length === 0) {
                return i18nc("@info:placeholder", "No images or camera found.")
            } else {
                return i18nc("@info:placeholder", "Support for your camera is not installed.")
            }
            explanation: if (importerHelper.loading || importerHelper.imageDirectory.toString().length === 0) {
                return '';
            } else {
                return i18nc("@info:placeholder", "After finishing the installation process, restart the importer to continue.");
            }
            visible: importerHelper.loading || !importerHelper.isMtpWorkerAvailable || importerHelper.imageDirectory.toString().length === 0

            helpfulAction: if (importerHelper.loading) {
                return null;
            } else if (importerHelper.isMtpWorkerAvailable && importerHelper.imageDirectory.toString().length === 0) {
                return refreshAction;
            } else {
                return installAction;
            }

            Kirigami.Action {
                id: installAction

                icon.name: "plasmadiscover"
                text: i18nc("@action:button", "Install Support for this Camera…")
                onTriggered: importerHelper.installKioWorker();
            }

            Kirigami.Action {
                id: refreshAction

                icon.name: "view-refresh-symbolic"
                text: i18nc("@action:button", "Refresh…")
                onTriggered: importerHelper.refresh();
            }
        }
    }
}
