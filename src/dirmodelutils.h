// SPDX-FileCopyrightText: 2019 Linus Jahn <lnj@kaidan.im>
//
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <QUrl>

class DirModelUtils : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QUrl home READ home CONSTANT)
    Q_PROPERTY(QUrl pictures READ pictures CONSTANT)
public:
    explicit DirModelUtils(QObject *parent = nullptr);

    QUrl home() const;
    QUrl pictures() const;

    Q_INVOKABLE QStringList getUrlParts(const QUrl &url) const;
    Q_INVOKABLE QUrl partialUrlForIndex(QUrl url, int index) const;
    Q_INVOKABLE bool canBeSimplified(QUrl url) const;
    Q_INVOKABLE QUrl directoryOfUrl(const QString &path) const;
    Q_INVOKABLE QString fileNameOfUrl(const QString &path) const;
    Q_INVOKABLE QUrl parentOfUrl(const QUrl &url) const;

    Q_INVOKABLE void mkdir(const QUrl &path) const;

Q_SIGNALS:
    void homePathChanged();
};
