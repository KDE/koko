// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "editorhelper.h"

#include <QDebug>

EditorHelper::EditorHelper(QObject *parent)
    : QObject(parent)
{
}

QImage EditorHelper::imageFromPath(const QString &path)
{
    QImage image(path);
    if (image.isNull()) {
        qWarning() << path << "is not a valid image";
    }

    return image;
}

bool EditorHelper::saveImageToPath(const QImage &image, const QString &path)
{
    return image.save(path);
}
