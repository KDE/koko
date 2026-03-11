/* SPDX-FileCopyrightText: 2026 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "resizehelper.h"

#include <QBuffer>
#include <QFileInfo>
#include <QImageWriter>
#include <KIO/Global>

ResizeHelper::ResizeHelper(QObject *parent)
    : QObject(parent)
{
}

QString ResizeHelper::fileSize(AnnotationDocument *doc, int width, int height, const QString &mimeType)
{
    if (!doc || width < 1 || height < 1) {
        return {};
    }
    auto image = doc->canvasBaseImage();
    QBuffer buffer;
    buffer.open(QIODevice::ReadWrite);
    // TODO: Find a cheaper way to estimate resized large images that is still fairly accurate and reliable.
    image = image.scaled(width, height, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    image.save(&buffer, QImageWriter::imageFormatsForMimeType(mimeType.toLatin1()).value(0));
    qint64 size = buffer.size();
    buffer.close();
    return KIO::convertSize(size);
}

QString ResizeHelper::fileSize(const QString &path)
{
    return KIO::convertSize(QFileInfo(path).size());
}
