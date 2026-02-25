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
    Q_PROPERTY(QList<QObject *> actions READ actions NOTIFY urlsChanged FINAL)
    Q_PROPERTY(QList<QUrl> urls READ urls WRITE setUrls NOTIFY urlsChanged FINAL)
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit FileMenuActions(QObject *parent = nullptr);

    QList<QObject *> actions() const;

    QList<QUrl> urls() const;
    void setUrls(const QList<QUrl> &urls);

Q_SIGNALS:
    void urlsChanged();

private:
    QList<QObject *> m_actions;
    QList<QUrl> m_urls;
};
