// Copied from Gwenview: an image viewer
// SPDX-FileCopyrightText: 2006 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QString>
#include <QUrl>

class KFileItem;

namespace MimeTypeUtils
{
const QStringList &rasterImageMimeTypes();
const QStringList &svgImageMimeTypes();
const QStringList &imageMimeTypes();

QString urlMimeType(const QUrl &);

enum Kind {
    KIND_UNKNOWN = 0,
    KIND_DIR = 1,
    KIND_FILE = 1 << 2,
    KIND_RASTER_IMAGE = 1 << 3,
    KIND_SVG_IMAGE = 1 << 4,
    KIND_VIDEO = 1 << 5,
};
Q_DECLARE_FLAGS(Kinds, Kind)

Kind fileItemKind(const KFileItem &);
Kind urlKind(const QUrl &);
Kind mimeTypeKind(const QString &mimeType);
}
