// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <QImage>
#include <QObject>
#include <qqmlregistration.h>

class EditorHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit EditorHelper(QObject *parent = nullptr);

    Q_INVOKABLE QImage imageFromPath(const QString &path);
    Q_INVOKABLE bool saveImageToPath(const QImage &image, const QString &path);
};
