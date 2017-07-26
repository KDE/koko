/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 * 
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "notificationmanager.h"

NotificationManager::NotificationManager(QObject* parent)
{
    Q_UNUSED(parent)
    m_sharingSuccess = new KNotification( "sharingSuccess", KNotification::Persistent);
    
    m_sharingFailed = new KNotification( "sharingFailed", KNotification::CloseOnTimeout);
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
        m_sharingSuccess->setText("Shared url for image is " + url.toString());
        m_sharingSuccess->sendEvent();
    } else {
        m_sharingFailed->sendEvent();
    }
}

#include "moc_notificationmanager.cpp"
