/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef NOTIFICATION_MANAGER_H
#define NOTIFICATION_MANAGER_H

#include <KNotification>
#include <qqmlregistration.h>

class NotificationManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit NotificationManager(QObject *parent = nullptr);
    ~NotificationManager() = default;

    /**
     * @argument valid: to check whether the returned url after sharing is valid or not
     * @argument url: the valid url returned after sharing the image
     */
    Q_INVOKABLE void showNotification(bool valid, const QVariant &url = QVariant());

private:
    KNotification *m_sharingSuccess;
    KNotification *m_sharingFailed;
};
#endif
