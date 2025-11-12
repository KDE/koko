/* SPDX-FileCopyrightText: 2025 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <QObject>
#include <QUrl>
#include <qqmlregistration.h>

class QWindow;

class PrinterHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool printerSupportAvailable READ printerSupportAvailable CONSTANT)

public:
    explicit PrinterHelper(QObject *parent = nullptr);
    static bool printerSupportAvailable();
    Q_INVOKABLE static void printFileFromUrl(const QUrl &fileUrl, QWindow *parent = nullptr);
};
