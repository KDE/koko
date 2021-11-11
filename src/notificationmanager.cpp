/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "notificationmanager.h"
#include <klocalizedstring.h>

NotificationManager::NotificationManager(QObject *parent)
    : QObject(parent)
{
    m_sharingSuccess = new KNotification("sharingSuccess", KNotification::Persistent, this);

    m_sharingFailed = new KNotification("sharingFailed", KNotification::CloseOnTimeout, this);
    m_sharingFailed->setText(i18n("Sharing failed"));
}

void NotificationManager::showNotification(bool valid, const QVariant &url)
{
    if (valid) {
        m_sharingSuccess->setText(i18n("Shared url for image is <a href='%1'>%1</a>", url.toString()));
        m_sharingSuccess->sendEvent();
    } else {
        m_sharingSuccess->setText(url.toString());
        m_sharingFailed->sendEvent();
    }
}
