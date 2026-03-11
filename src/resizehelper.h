/* SPDX-FileCopyrightText: 2026 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <QObject>
#include <qqmlregistration.h>
#include <KQuickImageEditor/AnnotationDocument>

/**
 * Get estimations for file size after resizing an image
 */
class ResizeHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit ResizeHelper(QObject *parent = nullptr);
    Q_INVOKABLE static QString fileSize(AnnotationDocument *doc, int width, int height, const QString &mimeType);
};
