/*
    SPDX-FileCopyrightText: 2016, 2019 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2025 Noah Davis <noahadvs@gmail.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <QObject>
#include <QUrl>
#include <qqmlregistration.h>

class QAction;

class QQuickItem;

class FileMenuActions : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QList<QObject *> actions READ actions NOTIFY urlChanged FINAL)
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged FINAL)
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit FileMenuActions(QObject *parent = nullptr);

    QList<QObject *> actions() const;

    QUrl url() const;
    void setUrl(const QUrl &url);

Q_SIGNALS:
    void urlChanged();

private:
    QList<QObject *> m_actions;
    QUrl m_url;
};
