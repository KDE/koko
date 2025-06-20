// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <QQuickWindow>
#include <QUrl>
#include <qqmlregistration.h>

class QQuickWindow;

class Controller : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Controller(QObject *parent = nullptr);

    // saveWindowGeometry and restoreWindowGeometry are only used for saving/restoring
    // the state when entering/leaving the slideshow mode
    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);
    Q_INVOKABLE void restoreWindowGeometry(QQuickWindow *window);

    Q_INVOKABLE Qt::KeyboardModifiers keyboardModifiers() const;
};
