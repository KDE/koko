/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.0-or-later
 */

#include "notificationmanager.h"
#include <klocalizedstring.h>

NotificationManager::NotificationManager(QObject *parent)
{
    Q_UNUSED(parent)
    m_sharingSuccess = new KNotification("sharingSuccess", KNotification::Persistent);

    m_sharingFailed = new KNotification("sharingFailed", KNotification::CloseOnTimeout);
    m_sharingFailed->setText("Sharing failed");
}

NotificationManager::~NotificationManager()
{
    delete m_sharingFailed;
    delete m_sharingSuccess;
}

void NotificationManager::showNotification(bool valid, QVariant url)
{
    if (valid) {
        m_sharingSuccess->setText(i18n("Shared url for image is <a href='%1'>%1</a>", url.toString()));
        m_sharingSuccess->sendEvent();
    } else {
        m_sharingFailed->sendEvent();
    }
}

#include "moc_notificationmanager.cpp"
