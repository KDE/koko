/*
   SPDX-FileCopyrightText: 2020 (c) Carl Schwan <carl@carlschwan.eu>

   SPDX-License-Identifier: LGPL-3.0-or-later
 */

#pragma once

#include <QStringList>
#include <QObject>

class ConfigurationHelper : public QObject
{
    Q_OBJECT

public:
    explicit ConfigurationHelper(QObject *parent = nullptr);
    ~ConfigurationHelper() {};
    Q_INVOKABLE QStringList processPaths(const QStringList &paths) const;
};
