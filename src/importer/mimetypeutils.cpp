// Copied from Gwenview: an image viewer
// SPDX-FileCopyrightText: 2006 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "mimetypeutils.h"

using namespace Qt::StringLiterals;

#include <KFileItem>

#include <QImageReader>
#include <QMimeDatabase>
#include <QStringView>

namespace MimeTypeUtils
{

static inline QString resolveAlias(const QString &name)
{
    static QMimeDatabase db;
    return db.mimeTypeForName(name).name();
}

static void resolveAliasInList(QStringList *list)
{
    QStringList::Iterator it = list->begin(), end = list->end();
    for (; it != end; ++it) {
        *it = resolveAlias(*it);
    }
}

// need to invent more intelligent way to whitelist raws
static constexpr auto rawMimeTypes = std::to_array<QLatin1StringView>({
    "image/x-nikon-nef"_L1,
    "image/x-nikon-nrw"_L1,
    "image/x-canon-cr2"_L1,
    "image/x-canon-crw"_L1,
    "image/x-pentax-pef"_L1,
    "image/x-adobe-dng"_L1,
    "image/x-sony-arw"_L1,
    "image/x-minolta-mrw"_L1,
    "image/x-panasonic-raw"_L1,
    "image/x-panasonic-raw2"_L1,
    "image/x-panasonic-rw"_L1,
    "image/x-panasonic-rw2"_L1,
    "image/x-samsung-srw"_L1,
    "image/x-olympus-orf"_L1,
    "image/x-fuji-raf"_L1,
    "image/x-kodak-dcr"_L1,
    "image/x-sigma-x3f"_L1,
});

const QStringList &rasterImageMimeTypes()
{
    static QStringList list;
    if (list.isEmpty()) {
        const auto supported = QImageReader::supportedMimeTypes();
        for (const auto &mime : supported) {
            const auto resolved = resolveAlias(QString::fromUtf8(mime));
            if (resolved.isEmpty()) {
                qWarning() << "Unresolved mime type " << mime;
            } else {
                list << resolved;
            }
        }
        // We don't want svg images to be considered as raster images
        const QStringList svgImageMimeTypesList = svgImageMimeTypes();
        for (const QString &mimeType : svgImageMimeTypesList) {
            list.removeOne(mimeType);
        }
        for (const QLatin1StringView &rawMimeType : rawMimeTypes) {
            const auto resolved = resolveAlias(rawMimeType);
            if (resolved.isEmpty()) {
                qWarning() << "Unresolved raw mime type " << rawMimeType;
            } else {
                if (!list.contains(resolved)) {
                    list << resolved;
                }
            }
        }
    }
    return list;
}

const QStringList &svgImageMimeTypes()
{
    static QStringList list;
    if (list.isEmpty()) {
        list << QStringLiteral("image/svg+xml") << QStringLiteral("image/svg+xml-compressed");
        resolveAliasInList(&list);
    }
    return list;
}

const QStringList &imageMimeTypes()
{
    static QStringList list;
    if (list.isEmpty()) {
        list = rasterImageMimeTypes();
        list += svgImageMimeTypes();
    }

    return list;
}

QString urlMimeType(const QUrl &url)
{
    if (url.isEmpty()) {
        return QStringLiteral("unknown");
    }

    QMimeDatabase db;
    return db.mimeTypeForUrl(url).name();
}

Kind mimeTypeKind(const QString &mimeType)
{
    if (rasterImageMimeTypes().contains(mimeType)) {
        return KIND_RASTER_IMAGE;
    }
    if (svgImageMimeTypes().contains(mimeType)) {
        return KIND_SVG_IMAGE;
    }
    if (mimeType.startsWith(QLatin1String("video/"))) {
        return KIND_VIDEO;
    }
    if (mimeType.startsWith(QLatin1String("inode/directory"))) {
        return KIND_DIR;
    }

    return KIND_FILE;
}

Kind fileItemKind(const KFileItem &item)
{
    if (item.isNull()) {
        return KIND_UNKNOWN;
    }
    return mimeTypeKind(item.mimetype());
}

Kind urlKind(const QUrl &url)
{
    return mimeTypeKind(urlMimeType(url));
}
}
