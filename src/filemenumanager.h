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

class FileMenuManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QList<QUrl> urls READ urls WRITE setUrls NOTIFY urlsChanged FINAL)
    Q_PROPERTY(bool enabled MEMBER m_enabled NOTIFY enabledChanged FINAL)
    QML_ELEMENT
public:
    explicit FileMenuManager(QObject *parent = nullptr);

    QList<QUrl> urls() const;
    void setUrls(const QList<QUrl> &urls);

Q_SIGNALS:
    void urlsChanged();
    void enabledChanged();

private:
    QList<QUrl> m_urls;
    bool m_enabled = false;
};
