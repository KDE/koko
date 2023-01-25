// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <QUrl>

class QQuickWindow;

class Controller : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);
    Q_INVOKABLE void restoreWindowGeometry(QQuickWindow *window);
    Q_INVOKABLE Qt::KeyboardModifiers keyboardModifiers() const;
};
