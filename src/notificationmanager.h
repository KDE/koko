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

#ifndef NOTIFICATION_MANAGER_H
#define NOTIFICATION_MANAGER_H

#include <knotification.h>
#include <QVariant>

class NotificationManager: public QObject
{
    Q_OBJECT
public:
    explicit NotificationManager(QObject *parent = 0);
    ~NotificationManager();
    
    /**
     * @argument valid: to check whether the returned url after sharing is valid or not
     * @argument url: the valid url returned after sharing the image
     */
    Q_INVOKABLE void showNotification(bool valid, QVariant url = QVariant());
    
private:
    KNotification *m_sharingSuccess;
    KNotification *m_sharingFailed;
    
};
#endif
