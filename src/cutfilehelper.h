/*
    SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class CutFileHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QList<QUrl> urls READ urls NOTIFY urlsChanged FINAL)

public:
    explicit CutFileHelper(QObject *parent = nullptr);

    [[nodiscard]] QList<QUrl> urls() const;

Q_SIGNALS:
    void urlsChanged();

private:
    void refresh();

    QList<QUrl> m_urls;
};
